import { format, parseISO, differenceInCalendarDays } from 'date-fns';

/** Task dates: "25 Feb" */
export const formatDate = (dateStr?: string): string => {
  if (!dateStr) return '-';
  try {
    return format(parseISO(dateStr), 'd MMM');
  } catch {
    return dateStr;
  }
};

/** Project dates: "26 Mar 2026" */
export const formatDateFull = (dateStr?: string): string => {
  if (!dateStr) return '-';
  try {
    return format(parseISO(dateStr), 'd MMM yyyy');
  } catch {
    return dateStr;
  }
};

/** Calculate days left from today to a given date string. Returns null if no date. */
export const getDaysLeft = (dateStr?: string | null): number | null => {
  if (!dateStr) return null;
  try {
    return differenceInCalendarDays(parseISO(dateStr), new Date());
  } catch {
    return null;
  }
};

/** Format days left into human-readable string */
export const formatDaysLeft = (dateStr?: string | null): string | null => {
  const days = getDaysLeft(dateStr);
  if (days === null) return null;
  if (days < 0) return `${Math.abs(days)}d overdue`;
  if (days === 0) return 'Today';
  return `${days}d left`;
};

/** Color class for days left */
export const daysLeftColor = (dateStr?: string | null): string => {
  const days = getDaysLeft(dateStr);
  if (days === null) return 'text-muted-foreground';
  if (days < 0) return 'text-destructive';
  if (days <= 3) return 'text-warning';
  return 'text-muted-foreground';
};

/** Smart project date range: same year → "23 Feb – 1 Mar 2026", different → "23 Feb 2025 – 1 Mar 2026" */
export const formatDateRange = (startStr?: string, endStr?: string): string => {
  if (!startStr && !endStr) return '-';
  if (!startStr) return formatDateFull(endStr);
  if (!endStr) return formatDateFull(startStr);
  try {
    const start = parseISO(startStr);
    const end = parseISO(endStr);
    if (start.getFullYear() === end.getFullYear()) {
      return `${format(start, 'd MMM')} – ${format(end, 'd MMM yyyy')}`;
    }
    return `${format(start, 'd MMM yyyy')} – ${format(end, 'd MMM yyyy')}`;
  } catch {
    return `${startStr} – ${endStr}`;
  }
};
