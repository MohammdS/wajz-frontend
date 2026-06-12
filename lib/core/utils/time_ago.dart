String timeAgo(DateTime time) {
  // Backend timestamps are naive UTC.
  final now = DateTime.now().toUtc();
  final utcTime = time.isUtc ? time : DateTime.utc(
    time.year, time.month, time.day, time.hour, time.minute, time.second);
  final diff = now.difference(utcTime);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${time.day}/${time.month}/${time.year}';
}
