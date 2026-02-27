
-- 1. Create enums
CREATE TYPE public.app_division AS ENUM ('creative', 'developer');
CREATE TYPE public.app_role AS ENUM ('super_admin', 'admin', 'member');
CREATE TYPE public.task_status AS ENUM ('todo', 'doing', 'review', 'done');
CREATE TYPE public.task_priority AS ENUM ('low', 'medium', 'high', 'urgent');
CREATE TYPE public.project_status AS ENUM ('planning', 'ongoing', 'completed', 'archived');

-- 2. Companies table
CREATE TABLE public.companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;

-- 3. Profiles table
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  avatar TEXT,
  position TEXT,
  division app_division NOT NULL DEFAULT 'creative',
  company_id UUID REFERENCES public.companies(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 4. User roles table (separate for security)
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role app_role NOT NULL DEFAULT 'member',
  UNIQUE(user_id, role)
);
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- 5. Projects table
CREATE TABLE public.projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT DEFAULT '',
  status project_status NOT NULL DEFAULT 'planning',
  division app_division NOT NULL DEFAULT 'creative',
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
  start_date DATE,
  end_date DATE,
  priority task_priority NOT NULL DEFAULT 'medium',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

-- 6. Tasks table
CREATE TABLE public.tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  status task_status NOT NULL DEFAULT 'todo',
  priority task_priority NOT NULL DEFAULT 'medium',
  assignee_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  request_date DATE DEFAULT CURRENT_DATE,
  due_date DATE,
  -- Creative fields
  moodboard_link TEXT,
  aspect_ratio TEXT,
  brand_guidelines TEXT,
  result_link TEXT,
  content_asset_link TEXT,
  -- Developer fields
  repo_link TEXT,
  environment TEXT,
  bug_severity TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

-- 7. Security definer helper functions
CREATE OR REPLACE FUNCTION public.get_user_role(_user_id UUID)
RETURNS app_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.user_roles WHERE user_id = _user_id LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.get_user_division(_user_id UUID)
RETURNS app_division
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT division FROM public.profiles WHERE id = _user_id LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.get_user_company(_user_id UUID)
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT company_id FROM public.profiles WHERE id = _user_id LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.is_super_admin(_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = 'super_admin'
  );
$$;

CREATE OR REPLACE FUNCTION public.is_admin_or_above(_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role IN ('super_admin', 'admin')
  );
$$;

-- 8. Auto-create profile on signup trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
    NEW.email
  );
  INSERT INTO public.user_roles (user_id, role)
  VALUES (NEW.id, 'member');
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 9. Updated_at trigger
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- 10. RLS Policies

-- Companies: everyone authenticated can read, super_admin can CRUD
CREATE POLICY "Anyone can read companies" ON public.companies FOR SELECT TO authenticated USING (true);
CREATE POLICY "Super admin can insert companies" ON public.companies FOR INSERT TO authenticated WITH CHECK (public.is_super_admin(auth.uid()));
CREATE POLICY "Super admin can update companies" ON public.companies FOR UPDATE TO authenticated USING (public.is_super_admin(auth.uid()));
CREATE POLICY "Super admin can delete companies" ON public.companies FOR DELETE TO authenticated USING (public.is_super_admin(auth.uid()));

-- Profiles: users can read same company, update own
CREATE POLICY "Users can read profiles in same company" ON public.profiles FOR SELECT TO authenticated
  USING (public.is_super_admin(auth.uid()) OR company_id = public.get_user_company(auth.uid()));
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE TO authenticated
  USING (id = auth.uid());
CREATE POLICY "Super admin can insert profiles" ON public.profiles FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid() OR public.is_super_admin(auth.uid()));

-- User roles: only super_admin can manage, users can read own
CREATE POLICY "Users can read own role" ON public.user_roles FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_super_admin(auth.uid()));
CREATE POLICY "Super admin can manage roles" ON public.user_roles FOR INSERT TO authenticated
  WITH CHECK (public.is_super_admin(auth.uid()));
CREATE POLICY "Super admin can update roles" ON public.user_roles FOR UPDATE TO authenticated
  USING (public.is_super_admin(auth.uid()));
CREATE POLICY "Super admin can delete roles" ON public.user_roles FOR DELETE TO authenticated
  USING (public.is_super_admin(auth.uid()));

-- Projects: super_admin all, admin own division, member can read own division
CREATE POLICY "Read projects" ON public.projects FOR SELECT TO authenticated
  USING (
    public.is_super_admin(auth.uid())
    OR (company_id = public.get_user_company(auth.uid()) AND (
      public.is_admin_or_above(auth.uid()) AND division = public.get_user_division(auth.uid())
      OR EXISTS (SELECT 1 FROM public.tasks WHERE tasks.project_id = projects.id AND tasks.assignee_id = auth.uid())
    ))
  );
CREATE POLICY "Admin can insert projects" ON public.projects FOR INSERT TO authenticated
  WITH CHECK (
    public.is_super_admin(auth.uid())
    OR (public.is_admin_or_above(auth.uid()) AND company_id = public.get_user_company(auth.uid()) AND division = public.get_user_division(auth.uid()))
  );
CREATE POLICY "Admin can update projects" ON public.projects FOR UPDATE TO authenticated
  USING (
    public.is_super_admin(auth.uid())
    OR (public.is_admin_or_above(auth.uid()) AND company_id = public.get_user_company(auth.uid()) AND division = public.get_user_division(auth.uid()))
  );
CREATE POLICY "Admin can delete projects" ON public.projects FOR DELETE TO authenticated
  USING (
    public.is_super_admin(auth.uid())
    OR (public.is_admin_or_above(auth.uid()) AND company_id = public.get_user_company(auth.uid()) AND division = public.get_user_division(auth.uid()))
  );

-- Tasks: super_admin all, admin own division, member assigned tasks
CREATE POLICY "Read tasks" ON public.tasks FOR SELECT TO authenticated
  USING (
    public.is_super_admin(auth.uid())
    OR assignee_id = auth.uid()
    OR (public.is_admin_or_above(auth.uid()) AND EXISTS (
      SELECT 1 FROM public.projects p WHERE p.id = tasks.project_id AND p.company_id = public.get_user_company(auth.uid()) AND p.division = public.get_user_division(auth.uid())
    ))
  );
CREATE POLICY "Admin can insert tasks" ON public.tasks FOR INSERT TO authenticated
  WITH CHECK (
    public.is_super_admin(auth.uid())
    OR (public.is_admin_or_above(auth.uid()) AND EXISTS (
      SELECT 1 FROM public.projects p WHERE p.id = project_id AND p.company_id = public.get_user_company(auth.uid()) AND p.division = public.get_user_division(auth.uid())
    ))
  );
CREATE POLICY "Admin or assignee can update tasks" ON public.tasks FOR UPDATE TO authenticated
  USING (
    public.is_super_admin(auth.uid())
    OR assignee_id = auth.uid()
    OR (public.is_admin_or_above(auth.uid()) AND EXISTS (
      SELECT 1 FROM public.projects p WHERE p.id = tasks.project_id AND p.company_id = public.get_user_company(auth.uid()) AND p.division = public.get_user_division(auth.uid())
    ))
  );
CREATE POLICY "Admin can delete tasks" ON public.tasks FOR DELETE TO authenticated
  USING (
    public.is_super_admin(auth.uid())
    OR (public.is_admin_or_above(auth.uid()) AND EXISTS (
      SELECT 1 FROM public.projects p WHERE p.id = tasks.project_id AND p.company_id = public.get_user_company(auth.uid()) AND p.division = public.get_user_division(auth.uid())
    ))
  );
