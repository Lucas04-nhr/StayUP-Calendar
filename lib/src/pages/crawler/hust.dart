import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../common_widgets.dart';
import '../../l10n.dart';
import '../../models.dart';
import '../widgets/school_importers.dart';

class HustImporter extends SchoolImporter {
  @override
  String get schoolId => 'hust';

  @override
  String displayName(BuildContext context) => context.l10n.schoolHust;

  @override
  String get pinyin => 'H';

  // 直接打开 JSON 接口，登录后 Cookie 会自动携带
  @override
  String get webUrl =>
      'http://mhub.hust.edu.cn/LsController/findNameCourse?kcbxqh=20252';

  @override
  String noticeText(BuildContext context) => context.l10n.hustNoticeText;

  @override
  String newScheduleName(BuildContext context) {
    final now = DateTime.now();
    return context.l10n.schoolImportScheduleName(displayName(context), now.month, now.day);
  }

  @override
  Future<List<Course>?> onPageLoaded(
    BuildContext context,
    WebViewController controller,
    AppState appState,
    void Function(String error) onError,
  ) async {
    try {
      final result = await controller.runJavaScriptReturningResult(
        'document.body.innerText',
      );

      // result 可能是带引号的 JSON 字符串，也可能已被平台解析
      String raw = result.toString();

      // 如果带外层引号（iOS WKWebView 的 JSON 编码），去掉并反转义
      if (raw.startsWith('"') && raw.endsWith('"')) {
        raw = jsonDecode(raw) as String;
      }

      if (raw.trim().startsWith('<') || raw.trim().isEmpty) {
        onError(context.l10n.hustNeedLoginError);
        return null;
      }

      final json = jsonDecode(raw) as Map<String, dynamic>;

      if (json['code'] != '200' || json['data'] == null) {
        onError(context.l10n.hustApiError(json['code']));
        return null;
      }

      return _parse(json, appState);
    } catch (e) {
      onError(context.l10n.hustReadFailed(e));
      return null;
    }
  }

  List<Course> _parse(Map<String, dynamic> json, AppState appState) {
    final existingIds = appState.courses.map((c) => c.id).toSet();
    int nextId = existingIds.isEmpty
        ? 1
        : existingIds.reduce((a, b) => a > b ? a : b) + 1;
    int colorIdx = 0;

    final courses = <Course>[];

    for (final item in json['data'] as List<dynamic>) {
      final name = (item['KCMC'] as String?)?.trim() ?? '';
      if (name.isEmpty) {
        continue;
      }

      final trs = (item['tr'] as List<dynamic>)
          .where((tr) =>
              tr['XQS'] != null &&
              tr['XQS'] != '<待定>' &&
              tr['QSJC'] != '<待定>')
          .toList();

      if (trs.isEmpty) {
        continue;
      }

      CourseSlot? parseSlot(dynamic tr) {
        try {
          return CourseSlot(
            day: int.parse(tr['XQS'].toString()),
            startSection: int.parse(tr['QSJC'].toString()),
            endSection: int.parse(tr['JSJC'].toString()),
            startWeek: int.parse(tr['QSZC'].toString()),
            endWeek: int.parse(tr['JSZC'].toString()),
          );
        } catch (_) {
          return null;
        }
      }

      final first = parseSlot(trs[0]);
      if (first == null) {
        continue;
      }

      final extras = <CourseSlot>[];
      for (int i = 1; i < trs.length; i++) {
        final slot = parseSlot(trs[i]);
        if (slot != null) {
          extras.add(slot);
        }
      }

      courses.add(Course(
        id: nextId++,
        name: name,
        teacher: trs[0]['XM']?.toString() ?? '',
        location: trs[0]['JSMC']?.toString() ?? '',
        day: first.day,
        startSection: first.startSection,
        span: first.endSection - first.startSection + 1,
        colorIdx: (colorIdx++) % kCourseColors.length,
        weeks: List.generate(
          first.endWeek - first.startWeek + 1,
          (i) => first.startWeek + i,
        ),
        startWeek: first.startWeek,
        endWeek: first.endWeek,
        extraSlots: extras,
      ));
    }

    return courses;
  }
}
