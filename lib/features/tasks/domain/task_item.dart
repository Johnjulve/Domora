import '../../records/domain/record.dart';

/// Priority levels for Tasks in Domora.
enum TaskPriority {
  low,
  medium,
  high,
  urgent;

  static TaskPriority fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'urgent':
        return TaskPriority.urgent;
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      case 'medium':
      default:
        return TaskPriority.medium;
    }
  }

  String get label {
    switch (this) {
      case TaskPriority.urgent:
        return 'Urgent';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }
}

/// Status lifecycle for Tasks in Domora.
enum TaskStatus {
  pending,
  inProgress,
  completed,
  cancelled;

  static TaskStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'cancelled':
        return TaskStatus.cancelled;
      case 'pending':
      default:
        return TaskStatus.pending;
    }
  }

  String get value {
    switch (this) {
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.completed:
        return 'completed';
      case TaskStatus.cancelled:
        return 'cancelled';
      case TaskStatus.pending:
        return 'pending';
    }
  }
}

/// Pure domain entity representing specialized Task & Responsibility metadata.
class TaskItem {
  final String recordId;
  final DateTime? dueDate;
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String status; // 'pending', 'in_progress', 'completed', 'cancelled'
  final DateTime? completedAt;
  final String? recurrenceRule;
  final String? assetRecordId;

  const TaskItem({
    required this.recordId,
    this.dueDate,
    this.priority = 'medium',
    this.status = 'pending',
    this.completedAt,
    this.recurrenceRule,
    this.assetRecordId,
  });

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending' || status == 'in_progress';

  bool isOverdue([DateTime? referenceDate]) {
    if (dueDate == null || isCompleted) return false;
    final now = referenceDate ?? DateTime.now();
    return dueDate!.isBefore(now);
  }

  bool isDueToday([DateTime? referenceDate]) {
    if (dueDate == null || isCompleted) return false;
    final now = referenceDate ?? DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  TaskItem copyWith({
    String? recordId,
    DateTime? dueDate,
    String? priority,
    String? status,
    DateTime? completedAt,
    String? recurrenceRule,
    String? assetRecordId,
  }) {
    return TaskItem(
      recordId: recordId ?? this.recordId,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      assetRecordId: assetRecordId ?? this.assetRecordId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskItem &&
          runtimeType == other.runtimeType &&
          recordId == other.recordId &&
          dueDate == other.dueDate &&
          priority == other.priority &&
          status == other.status &&
          completedAt == other.completedAt &&
          recurrenceRule == other.recurrenceRule &&
          assetRecordId == other.assetRecordId;

  @override
  int get hashCode => Object.hash(
        recordId,
        dueDate,
        priority,
        status,
        completedAt,
        recurrenceRule,
        assetRecordId,
      );
}

/// Composite domain entity holding a Record and its specialized Task metadata.
class RecordWithTask {
  final Record record;
  final TaskItem task;
  final String? linkedAssetTitle;

  const RecordWithTask({
    required this.record,
    required this.task,
    this.linkedAssetTitle,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordWithTask &&
          runtimeType == other.runtimeType &&
          record == other.record &&
          task == other.task &&
          linkedAssetTitle == other.linkedAssetTitle;

  @override
  int get hashCode => Object.hash(record, task, linkedAssetTitle);
}
