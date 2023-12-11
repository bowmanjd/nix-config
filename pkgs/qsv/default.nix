{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, sqlite
, zstd
, stdenv
, darwin
, python3
, file
}:

rustPlatform.buildRustPackage rec {
  pname = "qsv";
  version = "0.118.0";

  src = fetchFromGitHub {
    owner = "jqnatividad";
    repo = "qsv";
    rev = version;
    hash = "sha256-EVNqWETlKO7bpnh3rn6wjntgk5Xqa3/mnsu+hxu2UKk=";
  };

  postPatch = ''
    rm .cargo/config.toml;
  '';

  cargoHash = "sha256-qd+zk83KxGsqYq+4mzSLK3qhuRbe3h0jdbxvrC30S1s=";

  buildInputs =
    [
      sqlite
      zstd
      file
    ]
    ++ lib.optionals stdenv.isDarwin [
      darwin.apple_sdk.frameworks.CoreFoundation
      darwin.apple_sdk.frameworks.IOKit
      darwin.apple_sdk.frameworks.Security
    ];

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
    python3
  ];

  buildNoDefaultFeatures = true;

  buildFeatures = [ "all_features" ];

  checkFlags = [
    "--skip cmd::validate::test_load_json_via_url"
    "--skip test_comments::envlist"
    "--skip test_fetch::fetch_custom_header"
    "--skip test_fetch::fetch_custom_user_agent"
    "--skip test_fetch::fetch_jql_multiple"
    "--skip test_fetch::fetch_jql_multiple_file"
    "--skip test_fetch::fetch_jql_single"
    "--skip test_fetch::fetch_jql_single_file"
    "--skip test_fetch::fetch_ratelimit"
    "--skip test_fetch::fetch_simple"
    "--skip test_fetch::fetch_simple_new_col"
    "--skip test_fetch::fetch_simple_url_template"
    "--skip test_fetch::fetchpost_custom_user_agent"
    "--skip test_fetch::fetchpost_literalurl_test"
    "--skip test_fetch::fetchpost_simple_test"
    "--skip test_luau::luau_register_lookup_table_ckan"
    "--skip test_luau::luau_register_lookup_table_on_dathere_url"
    "--skip test_luau::luau_register_lookup_table_on_url"
    "--skip test_sniff::sniff_url"
    "--skip test_sniff::sniff_url_snappy"
    "--skip test_to::to_parquet_dir"
    "--skip test_validate::validate_adur_public_toilets_dataset_with_json_schema_url"
    "--skip test_apply::apply_calcconv"
    "--skip test_apply::apply_calcconv_invalid"
    "--skip test_apply::apply_calcconv_units"
    "--skip test_apply::apply_dynfmt"
    "--skip test_apply::apply_dynfmt_keepcase"
    "--skip test_describegpt::describegpt_invalid_api_key"
    "--skip test_fetch::fetch_complex_url_template"
    "--skip test_fetch::fetch_user_agent"
    "--skip test_foreach::foreach_multiple_commands_with_shell_script"
    "--skip test_geocode::geocode_countryinfo"
    "--skip test_geocode::geocode_countryinfo_formatstr"
    "--skip test_geocode::geocode_countryinfo_formatstr_pretty_json"
    "--skip test_geocode::geocode_countryinfonow"
    "--skip test_geocode::geocode_countryinfonow_formatstr"
    "--skip test_geocode::geocode_countryinfonow_formatstr_pretty_json"
    "--skip test_geocode::geocode_reverse"
    "--skip test_geocode::geocode_reverse_dyncols_fmt"
    "--skip test_geocode::geocode_reverse_fmtstring"
    "--skip test_geocode::geocode_reverse_fmtstring_intl"
    "--skip test_geocode::geocode_reverse_fmtstring_intl_dynfmt"
    "--skip test_geocode::geocode_reverse_fmtstring_intl_invalid_dynfmt"
    "--skip test_geocode::geocode_reversenow"
    "--skip test_geocode::geocode_suggest"
    "--skip test_geocode::geocode_suggest_dyncols_fmt"
    "--skip test_geocode::geocode_suggest_dynfmt"
    "--skip test_geocode::geocode_suggest_filter_country_admin1"
    "--skip test_geocode::geocode_suggest_fmt"
    "--skip test_geocode::geocode_suggest_fmt_cityrecord"
    "--skip test_geocode::geocode_suggest_fmt_json"
    "--skip test_geocode::geocode_suggest_intl"
    "--skip test_geocode::geocode_suggest_intl_admin1_filter_country_inferencing"
    "--skip test_geocode::geocode_suggest_intl_country_filter"
    "--skip test_geocode::geocode_suggest_intl_multi_country_filter"
    "--skip test_geocode::geocode_suggest_invalid"
    "--skip test_geocode::geocode_suggest_invalid_dynfmt"
    "--skip test_geocode::geocode_suggest_pretty_json"
    "--skip test_geocode::geocode_suggestnow"
    "--skip test_geocode::geocode_suggestnow_default"
    "--skip test_geocode::geocode_suggestnow_formatstr_dyncols"
    "--skip test_luau::luau_register_lookup_table"
    "--skip test_sample::sample_seed_url"
    "--skip test_snappy::snappy_decompress_url"
    "--skip test_sniff::sniff_justmime_remote"
  ];

  env = { ZSTD_SYS_USE_PKG_CONFIG = true; };

  meta = with lib; {
    description = "CSVs sliced, diced & analyzed";
    homepage = "https://github.com/jqnatividad/qsv";
    changelog = "https://github.com/jqnatividad/qsv/blob/${src.rev}/CHANGELOG.md";
    license = with licenses; [ unlicense /* or */ mit ];
    maintainers = [ {
      email = "git@bowmanjd.org";
      github = "bowmanjd";
      githubId = 86415;
      name = "Jonathan Bowman";
    } ];
  };
}
