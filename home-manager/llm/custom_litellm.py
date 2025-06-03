from typing import Literal, Optional, Union

import litellm
from litellm.caching.dual_cache import DualCache
from litellm.integrations.custom_logger import CustomLogger
from litellm.proxy._types import UserAPIKeyAuth


class MyCustomHandler(CustomLogger):
    async def async_pre_call_hook(
        self,
        user_api_key_dict: UserAPIKeyAuth,
        cache: DualCache,
        data: dict,
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
    ):
        model = data.get("model", "")
        if 'qwen' in model and not model.endswith('think'):
            messages = data.get("messages", [])
            for i, message in enumerate(messages):
                if message.get("role") == "system":
                    system_message = messages.pop(i)
                    break
            else:
                system_message = {"role": "system", "content": ""}
            system_message["content"] = " ".join([system_message.get("content", ""), ' /no_think']).lstrip()
            messages.insert(0, system_message)
            data["messages"] = messages
        return data

    def log_event(self, event_type, kwargs, response_obj):
        model = kwargs.get("model", None)
        messages = kwargs.get("messages", None)
        litellm_params = kwargs.get("litellm_params", {})
        metadata = litellm_params.get("metadata", {})
        model_group = metadata.get("model_group")
        deployment = metadata.get("deployment")
        cost = litellm.completion_cost(completion_response=response_obj)
        usage = response_obj.get("usage", None)
        content = next(item["content"] for item in messages if item["role"] == "user")
        first_10_words = " ".join(content.split()[:10])

        print(
            "\n".join(
                [
                    f"prompt: {first_10_words}",
                    f"model: {model}",
                    f"model_group: {model_group}",
                    f"deployment: {deployment}",
                    f"tokens: {usage.total_tokens}",
                    f"input_tokens: {usage.prompt_tokens}",
                    f"output_tokens: {usage.completion_tokens}",
                    f"cost: {cost}",
                ]
            )
        )

    # async def async_log_pre_api_call(self, model, messages, kwargs):
    #     print("Pre API Call:")
    #     print(f"model: {model} and messages: {messages}")

    async def async_log_success_event(self, kwargs, response_obj, start_time, end_time):
        self.log_event("Async Success", kwargs, response_obj)
        return

    async def async_log_failure_event(self, kwargs, response_obj, start_time, end_time):
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
