class TextResponse {
  @Deprecated('use fields instead')
  Data data;
  int get id => data.id;
  String get title => data.title;
  String get subtitle => data.subtitle;
  String get html => data.html;


  TextResponse({data});

  TextResponse.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (data != null) {
      data['data'] = this.data.toJson();
    }
    return data;
  }
}

class Data {
  int id;
  String title;
  String subtitle;
  String html;

  Data({id, title, subtitle, html});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    subtitle = json['subtitle'];
    html = json['html'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['subtitle'] = subtitle;
    data['html'] = html;
    return data;
  }
}
