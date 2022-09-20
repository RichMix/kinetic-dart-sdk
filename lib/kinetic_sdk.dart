library kinetic;

import 'package:kinetic/generated/lib/api.dart';
import 'package:kinetic/helpers/get_solana_rpc_endpoint.dart';
import 'package:kinetic/interfaces/create_account_options.dart';
import 'package:kinetic/interfaces/get_balance_options.dart';
import 'package:kinetic/interfaces/get_history_options.dart';
import 'package:kinetic/interfaces/get_token_accounts_options.dart';
import 'package:kinetic/interfaces/kinetic_sdk_config.dart';
import 'package:kinetic/interfaces/make_transfer_options.dart';
import 'package:kinetic/interfaces/request_airdrop_options.dart';
import 'package:kinetic/kinetic_sdk_internal.dart';
import 'package:kinetic/solana.dart';

class KineticSdk {
  late Solana solana;

  late KineticSdkInternal _internal;
  final KineticSdkConfig sdkConfig;

  KineticSdk(this.sdkConfig) {
    _internal = KineticSdkInternal(sdkConfig);
  }

  AppConfig? get config => _internal.appConfig;

  String? get endpoint => sdkConfig?.endpoint;

  Future<Transaction?> createAccount({required CreateAccountOptions options}) async {
    return _internal.createAccount(options);
  }

  Future<BalanceResponse?> getBalance({required GetBalanceOptions options}) async {
    return _internal.getBalance(options.account);
  }

  Future<String?> getExplorerUrl(String path) async {
    return _internal?.appConfig?.environment?.explorer.replaceAll("{path}", path);
  }

  Future<List<HistoryResponse>?> getHistory({required GetHistoryOptions options}) async {
    return _internal.getHistory(options);
  }

  Future<List<String>?> getTokenAccounts({required GetTokenAccountsOptions options}) async {
    return _internal.getTokenAccounts(options);
  }

  Future<Transaction?> makeTransfer({required MakeTransferOptions options}) async {
    return _internal.makeTransfer(options);
  }

  Future<RequestAirdropResponse?> requestAirdrop({required RequestAirdropOptions options}) async {
    return _internal.requestAirdrop(options);
  }

  Future<AppConfig?> init() async {
    try {
      sdkConfig?.logger?.i('KineticSdk: initializing KineticSdk');

      var config = await _internal.getAppConfig(sdkConfig.environment, sdkConfig.index);

      sdkConfig.solanaRpcEndpoint = sdkConfig?.solanaRpcEndpoint != null
          ? getSolanaRpcEndpoint(sdkConfig?.solanaRpcEndpoint as String)
          : getSolanaRpcEndpoint(config?.environment?.cluster?.endpoint as String);

      sdkConfig.solanaWssEndpoint = sdkConfig?.solanaRpcEndpoint?.replaceAll('http', 'ws') as String;

      solana = Solana(
        solanaRpcEndpoint: sdkConfig.solanaRpcEndpoint as String,
        solanaWssEndpoint: sdkConfig.solanaWssEndpoint as String,
        timeoutDuration: const Duration(seconds: 60),
      );

      sdkConfig?.logger?.i(
          "KineticSdk: endpoint '${sdkConfig.endpoint}', environment '${sdkConfig.environment}', index: ${config?.app.index}");
      return config;
    } catch (e) {
      sdkConfig?.logger?.e('Error initializing Server. ${e.toString()}');
      rethrow;
    }
  }

  static Future<KineticSdk> setup({required KineticSdkConfig sdkConfig}) async {
    var sdk = KineticSdk(sdkConfig);
    try {
      await sdk.init();
      sdkConfig?.logger?.i('Kinetic SDK Setup Done');
      return sdk;
    } catch (e) {
      sdkConfig?.logger?.e('Error setting up SDK. ${e.toString()}');
      rethrow;
    }
  }
}
