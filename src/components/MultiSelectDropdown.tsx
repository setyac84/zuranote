import { useState, useRef, useEffect } from 'react';
import { ChevronDown, Check } from 'lucide-react';
import { cn } from '@/lib/utils';

interface MultiSelectDropdownProps {
  options: { value: string; label: string }[];
  selectedValues: string[];
  onChange: (values: string[]) => void;
  placeholder?: string;
  className?: string;
}

const MultiSelectDropdown = ({ options, selectedValues, onChange, placeholder = 'Select...', className }: MultiSelectDropdownProps) => {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    };
    if (open) document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, [open]);

  const toggle = (value: string) => {
    onChange(
      selectedValues.includes(value)
        ? selectedValues.filter(v => v !== value)
        : [...selectedValues, value]
    );
  };

  const selectedLabels = options.filter(o => selectedValues.includes(o.value)).map(o => o.label);
  const displayText = selectedLabels.length > 0 ? selectedLabels.join(', ') : placeholder;

  return (
    <div className={cn("relative", className)} ref={ref}>
      <button type="button" onClick={() => setOpen(!open)}
        className="flex items-center justify-between w-full bg-secondary/50 border border-border rounded-lg px-3 py-1.5 text-xs text-foreground hover:border-primary/40 transition-colors">
        <span className={cn("truncate", selectedLabels.length === 0 && 'text-muted-foreground')}>{displayText}</span>
        <ChevronDown className={cn("w-4 h-4 text-muted-foreground transition-transform shrink-0 ml-2", open && "rotate-180")} />
      </button>
      {open && (
        <div className="absolute top-full left-0 right-0 mt-1.5 bg-popover border border-border rounded-2xl shadow-xl z-[70] p-2.5 max-h-[220px] overflow-y-auto space-y-1">
          {options.map(opt => (
            <button key={opt.value} type="button" onClick={() => toggle(opt.value)}
              className={cn('w-full text-left px-3 py-2 text-sm rounded-xl transition-colors flex items-center gap-2',
                selectedValues.includes(opt.value) ? 'font-medium bg-accent text-accent-foreground' : 'text-foreground hover:bg-accent/60 hover:text-accent-foreground')}>
              <Check className={cn("w-3.5 h-3.5 shrink-0", selectedValues.includes(opt.value) ? "opacity-100" : "opacity-0")} />
              {opt.label}
            </button>
          ))}
        </div>
      )}
    </div>
  );
};

export default MultiSelectDropdown;
