import 'package:flutter/material.dart';
import 'models.dart';
import 'l10n.dart';
import 'common_widgets.dart';

/// 课程提醒管理器，处理所有与课前提醒相关的逻辑
class CourseReminderManager {
  /// 检查课程是否包含给定的周和星期
  static bool courseContainsDateAndDay(Course course, DateTime date, List<int> weeks) {
    final courseWeeks = course.weeks;
    final targetWeekday = date.weekday;
    
    // 检查课程是否在周列表中，且课程的周一至周日与目标日期匹配
    return courseWeeks.any((w) => weeks.contains(w)) && course.day == targetWeekday;
  }

  /// 时间字符串转分钟数（"08:30" -> 510）
  static int timeStringToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// 从所有课程中获取下一节课程
  static Course? getNextUpcomingCourse(
    List<Course> courses,
    DateTime today,
    int todayWeek,
    int todayWeekday,
    List<List<String>> customTimes,
    int reminderMinutes,
  ) {
    final nowMinutes = DateTime.now().hour * 60 + DateTime.now().minute;

    for (final course in courses) {
      // 检查课程是否在今天
      if (course.day != todayWeekday) continue;
      if (!course.weeks.contains(todayWeek)) continue;

      // 获取课程开始时间
      if (course.startSection < 1 || course.startSection > customTimes.length) continue;
      final startTimeStr = customTimes[course.startSection - 1][0];
      final startMinutes = timeStringToMinutes(startTimeStr);

      // 计算距离上课还有多少分钟
      final minutesUntilClass = startMinutes - nowMinutes;

      // 如果在 0-reminderMinutes 分钟之间，则返回这个课程
      if (minutesUntilClass > 0 && minutesUntilClass <= reminderMinutes) {
        return course;
      }
    }

    return null;
  }

  /// 显示下一节课提醒弹窗
  static void showUpcomingClassReminder(
    BuildContext context,
    Course course,
    int minutesUntilClass,
    String startTimeStr,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: ac(context).card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          context.l10n.schedulePageUpcomingClass,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 课程名称
            Text(
              course.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A2E),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // 时间信息
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Color(0xFF888888)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$startTimeStr ${context.l10n.schedulePageRemainMinutes(minutesUntilClass)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
              ],
            ),
            if (course.location.isNotEmpty) ...[
              const SizedBox(height: 8),
              // 位置信息
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Color(0xFF888888)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      course.location,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (course.teacher.isNotEmpty) ...[
              const SizedBox(height: 8),
              // 教师信息
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Color(0xFF888888)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      course.teacher,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.l10n.okAction,
              style: TextStyle(color: ac(context).hint),
            ),
          ),
        ],
      ),
    );
  }
}
