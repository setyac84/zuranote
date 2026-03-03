import { useState, useRef, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search, X, FolderKanban, ListTodo } from 'lucide-react';
import { useProjects, useTasks } from '@/hooks/useSupabaseData';
import { useAuth } from '@/contexts/AuthContext';
import { cn } from '@/lib/utils';

const GlobalSearch = () => {
  const [query, setQuery] = useState('');
  const [focused, setFocused] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const navigate = useNavigate();
  const { activeDivision } = useAuth();
  const { data: projects = [] } = useProjects();
  const { data: tasks = [] } = useTasks();

  useEffect(() => {
    const handleKey = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        inputRef.current?.focus();
      }
      if (e.key === 'Escape') {
        inputRef.current?.blur();
        setQuery('');
      }
    };
    window.addEventListener('keydown', handleKey);
    return () => window.removeEventListener('keydown', handleKey);
  }, []);

  // Close dropdown on outside click
  useEffect(() => {
    const handleClick = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setFocused(false);
      }
    };
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, []);

  const q = query.toLowerCase().trim();

  const filteredProjects = q
    ? projects.filter(p => p.division_id === activeDivision && p.name.toLowerCase().includes(q)).slice(0, 5)
    : [];

  const filteredTasks = q
    ? tasks.filter(t => {
        const project = projects.find(p => p.id === t.project_id);
        return project?.division_id === activeDivision && t.title.toLowerCase().includes(q);
      }).slice(0, 5)
    : [];

  const hasResults = filteredProjects.length > 0 || filteredTasks.length > 0;
  const showDropdown = focused && q.length > 0;

  const handleSelect = (type: 'project' | 'task', id: string) => {
    setQuery('');
    setFocused(false);
    inputRef.current?.blur();
    if (type === 'project') {
      navigate(`/tasks?project=${id}`);
    } else {
      navigate(`/tasks`);
    }
  };

  return (
    <div ref={containerRef} className="relative w-full max-w-xs sm:max-w-sm">
      {/* Inline search input */}
      <div className={cn(
        "flex items-center gap-2 px-3 py-1.5 text-sm bg-secondary/60 border rounded-lg transition-colors",
        focused ? "border-primary/50 ring-1 ring-primary/20" : "border-border hover:border-primary/30"
      )}>
        <Search className="w-4 h-4 text-muted-foreground shrink-0" />
        <input
          ref={inputRef}
          value={query}
          onChange={e => setQuery(e.target.value)}
          onFocus={() => setFocused(true)}
          placeholder="Search tasks or projects..."
          className="flex-1 bg-transparent text-sm text-foreground placeholder:text-muted-foreground outline-none min-w-0"
        />
        {query ? (
          <button onClick={() => setQuery('')} className="text-muted-foreground hover:text-foreground">
            <X className="w-4 h-4" />
          </button>
        ) : (
          <kbd className="hidden sm:inline-flex items-center gap-0.5 px-1.5 py-0.5 text-[10px] font-medium text-muted-foreground bg-muted rounded">
            ⌘K
          </kbd>
        )}
      </div>

      {/* Dropdown results */}
      {showDropdown && (
        <div className="absolute top-full left-0 right-0 mt-1.5 bg-popover border border-border rounded-2xl shadow-xl z-50 overflow-hidden">
          <div className="max-h-[50vh] overflow-y-auto p-2">
            {filteredProjects.length > 0 && (
              <div className="mb-2">
                <p className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold px-2 py-1">Projects</p>
                {filteredProjects.map(p => (
                  <button key={p.id} onClick={() => handleSelect('project', p.id)}
                    className="w-full flex items-center gap-2.5 px-3 py-2 text-sm text-foreground rounded-lg hover:bg-secondary/50 transition-colors text-left">
                    <FolderKanban className="w-4 h-4 text-primary shrink-0" />
                    <span className="truncate">{p.name}</span>
                    <span className="ml-auto text-[10px] text-muted-foreground capitalize">{p.status}</span>
                  </button>
                ))}
              </div>
            )}
            {filteredTasks.length > 0 && (
              <div>
                <p className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold px-2 py-1">Tasks</p>
                {filteredTasks.map(t => (
                  <button key={t.id} onClick={() => handleSelect('task', t.id)}
                    className="w-full flex items-center gap-2.5 px-3 py-2 text-sm text-foreground rounded-lg hover:bg-secondary/50 transition-colors text-left">
                    <ListTodo className="w-4 h-4 text-info shrink-0" />
                    <span className="truncate">{t.title}</span>
                    <span className="ml-auto text-[10px] text-muted-foreground capitalize">{t.status}</span>
                  </button>
                ))}
              </div>
            )}
            {!hasResults && (
              <p className="text-center text-sm text-muted-foreground py-6">No results found.</p>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default GlobalSearch;
