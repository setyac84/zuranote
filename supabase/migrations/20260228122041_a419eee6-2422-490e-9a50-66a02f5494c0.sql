
-- Fix companies DELETE: allow scoped super_admin to delete sub-companies in their group
DROP POLICY IF EXISTS "Admin can delete companies" ON public.companies;
CREATE POLICY "Super admin can delete companies"
ON public.companies FOR DELETE
TO authenticated
USING (
  is_super_admin(auth.uid())
  AND (
    get_user_company(auth.uid()) IS NULL
    OR is_in_user_company_group(auth.uid(), id)
  )
);
