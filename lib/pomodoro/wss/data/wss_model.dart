class WssModel {
  WssModel({this.success, this.code, this.data});

  WssModel.fromJson(dynamic json) {
    success = json['success'];
    code = json['code'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }
  num? success;
  num? code;
  Data? data;
  WssModel copyWith({num? success, num? code, Data? data}) => WssModel(
    success: success ?? this.success,
    code: code ?? this.code,
    data: data ?? this.data,
  );
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['code'] = code;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }
}

class Data {
  Data({this.type, this.remainingTime, this.timerId, this.sequenceId});

  Data.fromJson(dynamic json) {
    type = json['type'];
    remainingTime = json['remainingTime'];
    timerId = json['timerId'];
    sequenceId = json['sequenceId'];
  }
  num? type;
  String? remainingTime;
  num? timerId;
  num? sequenceId;
  Data copyWith({
    num? type,
    String? remainingTime,
    num? timerId,
    num? sequenceId,
  }) => Data(
    type: type ?? this.type,
    remainingTime: remainingTime ?? this.remainingTime,
    timerId: timerId ?? this.timerId,
    sequenceId: sequenceId ?? this.sequenceId,
  );
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['type'] = type;
    map['remainingTime'] = remainingTime;
    map['timerId'] = timerId;
    map['sequenceId'] = sequenceId;
    return map;
  }
}
