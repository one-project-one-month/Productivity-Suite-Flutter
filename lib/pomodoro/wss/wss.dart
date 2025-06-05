import 'package:socket_io_client/socket_io_client.dart';

import '../configs/constant.dart';

class WSS {
  late Socket socket;
  void connect() {
    socket = io(Uri.parse(Constant.wssUrl));
    socket.onConnect((v) {});
  }
}
