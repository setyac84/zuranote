import { format, parseISO } from 'date-fns';

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
