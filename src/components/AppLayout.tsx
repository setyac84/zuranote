import { ReactNode, useState, useEffect } from 'react';
import Sidebar from '@/components/Sidebar';
import GlobalSearch from '@/components/GlobalSearch';
import { useAuth } from '@/contexts/AuthContext';
import { Navigate } from 'react-router-dom';
import { Loader2 } from 'lucide-react';
import { format } from 'date-fns';

const DigitalClock = () => {
  const [time, setTime] = useState(new Date());
  useEffect(() => {
    const timer = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);
  const hours = format(time, 'HH');
  const minutes = format(time, 'mm');
  const seconds = format(time, 'ss');
  return (
    <span className="inline-flex items-baseline gap-0.5 tabular-nums">
      <span className="text-sm font-bold text-foreground tracking-tight">{hours}</span>
      <span className="text-sm font-bold text-foreground">:</span>
      <span className="text-sm font-bold text-foreground tracking-tight">{minutes}</span>
      <span className="text-sm font-bold text-foreground">:</span>
      <span className="text-sm font-bold text-muted-foreground tracking-tight">{seconds}</span>
    </span>
  );
};

const TopDateBar = () => {
  return (
    <div className="flex items-center gap-2 text-xs text-muted-foreground whitespace-nowrap">
      <span>Today is</span>
      <span className="font-bold bg-primary/10 text-primary px-2 py-0.5 rounded-md">
        {format(new Date(), 'EEEE, d MMM yyyy')}
      </span>
      <DigitalClock />
    </div>
  );
};

const AppLayout = ({ children }: { children: ReactNode }) => {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <Loader2 className="w-8 h-8 animate-spin text-primary" />
      </div>
    );
  }

  if (!user) return <Navigate to="/" replace />;

  return (
    <div className="min-h-screen bg-background">
      <Sidebar />
      {/* Top bar - desktop */}
      <div className="hidden lg:flex fixed top-0 left-52 right-0 h-14 items-center justify-between px-6 z-30 bg-background/80 backdrop-blur-sm border-b border-border">
        <TopDateBar />
        <GlobalSearch />
      </div>
      {/* Top bar - mobile */}
      <div className="lg:hidden px-4 pt-[60px] pb-2 space-y-2">
        <div className="flex items-center justify-center">
          <TopDateBar />
        </div>
        <div className="flex justify-center">
          <GlobalSearch />
        </div>
      </div>
      <main className="p-4 pt-2 lg:pt-[72px] lg:pl-56 lg:pr-6">
        {children}
      </main>
    </div>
  );
};

export default AppLayout;
