
-- Create task_assignees junction table for multiple assignees per task
CREATE TABLE public.task_assignees (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  assignee_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(task_id, assignee_id)
);

-- Enable RLS
ALTER TABLE public.task_assignees ENABLE ROW LEVEL SECURITY;

-- RLS policies - same access pattern as tasks
CREATE POLICY "Users can view task assignees" ON public.task_assignees
  FOR SELECT USING (true);

CREATE POLICY "Admins can manage task assignees" ON public.task_assignees
  FOR ALL USING (
    public.is_admin_or_above(auth.uid())
  );

-- Migrate existing assignee_id data to the junction table
INSERT INTO public.task_assignees (task_id, assignee_id)
SELECT id, assignee_id FROM public.tasks WHERE assignee_id IS NOT NULL
ON CONFLICT DO NOTHING;

-- Create index for performance
CREATE INDEX idx_task_assignees_task_id ON public.task_assignees(task_id);
CREATE INDEX idx_task_assignees_assignee_id ON public.task_assignees(assignee_id);
