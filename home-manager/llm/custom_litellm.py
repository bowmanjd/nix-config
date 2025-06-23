"""
Custom LiteLLM handler that adjusts system messages for certain models and provides detailed logging with cost/token info.

- Modifies messages for "qwen" models to insert '/no_think' into the system prompt.
- Logs completions (with costs, token counts, deployment/metadata details).
- Handles async pre-call hooks and logs both success and failure events for API calls.

Intended to be used as a proxy handler for LiteLLM.
"""

from typing import Literal, Optional, Union, Dict, Any

import litellm
from litellm.caching.dual_cache import DualCache
from litellm.integrations.custom_logger import CustomLogger
from litellm.proxy._types import UserAPIKeyAuth


class MyCustomHandler(CustomLogger):
    """
    A custom handler for LiteLLM proxy that modifies system prompts for certain models
    and provides detailed event logging.

    Inherits from:
        CustomLogger (from LiteLLM)
    """

    async def async_pre_call_hook(
        self,
        user_api_key_dict: UserAPIKeyAuth,
        cache: DualCache,
        data: Dict[str, Any],
        call_type: Literal[
            "acompletion",
            "completion",
            "text_completion",
            "embeddings",
            "image_generation",
            "moderation",
            "audio_transcription",
            "pass_through_endpoint",
            "rerank",
        ],
    ) -> Dict[str, Any]:
        """
        Async hook called before forwarding a call to a backing model.

        - For 'qwen' models (not ending in 'think'), modifies/inserts the system prompt to include '/no_think'.
        - Returns possibly-mutated data dict.

        Args:
            user_api_key_dict: User API key object
            cache: DualCache (request cache)
            data: The full proxy call data, including "messages", "model", etc.
            call_type: Type of the proxy call

        Returns:
            Mutated data dict (with possibly updated 'messages').
        """
        model = data.get("model", "")
        messages = data.get("messages", [])
        if not isinstance(messages, list):
            messages = []
        if 'qwen' in model and not model.endswith('think'):
            # Find and extract system message, or create it if absent
            sys_idx = next((i for i, m in enumerate(messages) if m.get("role") == "system"), None)
            if sys_idx is not None:
                system_message = messages.pop(sys_idx)
            else:
                system_message = {"role": "system", "content": ""}
            # Ensure '/no_think' is appended
            system_message["content"] = " ".join([system_message.get("content", ""), '/no_think']).strip()
            messages.insert(0, system_message)
            data["messages"] = messages
        return data

    def log_event(self, event_type: str, kwargs: dict, response_obj: dict):
        """
        Logs proxy API events, including token and cost statistics, model metadata, and a preview of the prompt.

        - Handles free-cost providers (like GitHub Copilot).
        - Prints counts and identifiers for prompt, cost, tokens, etc.

        Args:
            event_type: String label for the event type (e.g., 'Async Success', 'Async Failure').
            kwargs: Parameters from the API request, including model and messages.
            response_obj: Completion or generation response returned by the model.
        """

        print(f"\nkwargs: {kwargs}\n")
        model = kwargs.get("model")
        messages = kwargs.get("messages")
        litellm_params = kwargs.get("litellm_params", {})
        metadata = litellm_params.get("metadata", {})
        model_group = metadata.get("model_group")
        deployment = metadata.get("deployment")
        model_id = metadata.get("model_info", {}).get("id")
        api_base = metadata.get("api_base")

        if response_obj is None:
            print(f"Logging warning: response_obj is None for event_type={event_type}, model={model}")
            return

        if api_base and "githubcopilot" in api_base:
            cost = 0.0
        else:
            cost = litellm.completion_cost(completion_response=response_obj)

        usage = response_obj.get("usage") or {}
        total_tokens = usage.get("total_tokens", 0)
        prompt_tokens = usage.get("prompt_tokens", 0)
        completion_tokens = usage.get("completion_tokens", 0)

        if not messages:
            content = ""
        else:
            content = next((item["content"] for item in messages if item["role"] == "user"), "")
        first_10_words = " ".join(content.split()[:10])

        print(
            "\n".join(
                [
                    f"prompt: {first_10_words}",
                    f"model: {model}",
                    f"model_group: {model_group}",
                    f"model_id: {model_id}",
                    f"deployment: {deployment}",
                    f"api_base: {api_base}",
                    f"tokens: {total_tokens}",
                    f"input_tokens: {prompt_tokens}",
                    f"output_tokens: {completion_tokens}",
                    f"cost: {cost}",
                ]
            )
        )

    async def async_log_success_event(self, kwargs, response_obj, start_time, end_time):
        """
        Async hook for logging successful API completion calls.

        Args:
            kwargs: Request parameters.
            response_obj: Model response object.
            start_time: Time when the call started.
            end_time: Time when the call finished.
        """
        self.log_event("Async Success", kwargs, response_obj)
        return

    async def async_log_failure_event(self, kwargs, response_obj, start_time, end_time):
        """
        Async hook for logging failed API completion calls.

        Args:
            kwargs: Request parameters (should contain exception info).
            response_obj: Model response object (may be None).
            start_time: Time when the call started.
            end_time: Time when the call failed.
        """
        exception_event = kwargs.get("exception", None)
        traceback_event = kwargs.get("traceback_exception", None)
        self.log_event("Async Failure", kwargs, response_obj)
        print(
            f"""
                Exception: {exception_event}
                Traceback: {traceback_event}
            """
        )


proxy_handler_instance = MyCustomHandler()
