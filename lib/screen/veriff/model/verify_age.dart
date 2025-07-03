import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:veriff_flutter/veriff_flutter.dart';

class VerifyAge {
  static const String _veriffEndpoint =
      "https://staging.vendron.com/v2/test/generate_veriff_session";

  static Future<VeriffResult> startVeriffSession() async {
    bool isSuccess = false;
    String? errMsg;

    final Dio dio = Dio();

    final request = await dio.get(_veriffEndpoint);

    final requestData =
        (request.data != null && (request.data is Map<String, dynamic>))
            ? (request.data as Map<String, dynamic>)
            : null;

    if (requestData != null) {
      if (requestData.containsKey("status") &&
          requestData["status"] == true &&
          requestData.containsKey("response") &&
          (requestData["response"] is Map<String, dynamic>) &&
          (requestData["response"] as Map<String, dynamic>).containsKey(
            "session_url",
          )) {
        final Configuration configuration = Configuration(
          requestData["response"]["session_url"],
        );

        final Veriff veriff = Veriff();
        try {
          final Result veriffResult = await veriff.start(configuration);

          switch (veriffResult.status) {
            case Status.done:
              isSuccess = true;
              break;
            case Status.canceled:
              errMsg = "Session Cancelled";
              break;
            case Status.error:
              final errMsgList = {
                Error.cameraUnavailable: "Unable to open camera",
                Error.microphoneUnavailable: "Unable to open microphone",
                Error.networkError: "Network Error",
                Error.sessionError: "Veriff session error",
                Error.deprecatedSDKVersion: "Internal error",
                Error.nfcError: "NFC error",
                Error.setupError: "Internal error",
                Error.unknown: "Veriff unknown error",
              };
              errMsg = errMsgList[veriffResult.error] ?? "Unknown Error";
              break;
          }
        } on PlatformException catch (e) {
          errMsg = e.message;
        } catch (e) {
          errMsg = e.toString();
        }
      }
    }

    return VeriffResult(status: isSuccess, errMsg: errMsg);
  }
}

class VeriffResult {
  final bool status;
  final String? errMsg;

  const VeriffResult({required this.status, required this.errMsg});
}
