
-- Allow admin (not just super_admin) to insert companies
DROP POLICY "Super admin can insert companies" ON public.companies;
CREATE POLICY "Admin can insert companies"
ON public.companies FOR INSERT TO authenticated
WITH CHECK (is_admin_or_above(auth.uid()));

-- Allow admin to update companies (scoped)
DROP POLICY "Super admin can update companies" ON public.companies;
CREATE POLICY "Admin can update companies"
ON public.companies FOR UPDATE TO authenticated
USING (is_admin_or_above(auth.uid()) AND ((get_user_company(auth.uid()) IS NULL) OR (id = get_user_company(auth.uid()))));

-- Allow admin to delete companies (holding only)
DROP POLICY "Super admin can delete companies" ON public.companies;
CREATE POLICY "Admin can delete companies"
ON public.companies FOR DELETE TO authenticated
USING (is_admin_or_above(auth.uid()) AND (get_user_company(auth.uid()) IS NULL));
