
-- Drop the restrictive insert policy
DROP POLICY IF EXISTS "Admin+ can insert companies" ON public.companies;

-- Recreate as explicitly PERMISSIVE
CREATE POLICY "Admin+ can insert companies"
ON public.companies
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.user_companies
    WHERE user_id = auth.uid()
    AND role IN ('owner', 'super_admin', 'admin')
  )
);

-- Also fix the other restrictive policies to be permissive
DROP POLICY IF EXISTS "Read companies" ON public.companies;
CREATE POLICY "Read companies"
ON public.companies
FOR SELECT
TO authenticated
USING (user_belongs_to_company(auth.uid(), id));

DROP POLICY IF EXISTS "Owner/super can update companies" ON public.companies;
CREATE POLICY "Owner/super can update companies"
ON public.companies
FOR UPDATE
TO authenticated
USING (is_owner_or_super(auth.uid()) AND user_belongs_to_company(auth.uid(), id));

DROP POLICY IF EXISTS "Owner/super can delete companies" ON public.companies;
CREATE POLICY "Owner/super can delete companies"
ON public.companies
FOR DELETE
TO authenticated
USING (is_owner_or_super(auth.uid()) AND user_belongs_to_company(auth.uid(), id));

-- Also fix user_companies INSERT policy so admin can create the association
DROP POLICY IF EXISTS "Owner/super can insert user_companies" ON public.user_companies;
CREATE POLICY "Admin+ can insert user_companies"
ON public.user_companies
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.user_companies
    WHERE user_id = auth.uid()
    AND role IN ('owner', 'super_admin', 'admin')
  )
);
