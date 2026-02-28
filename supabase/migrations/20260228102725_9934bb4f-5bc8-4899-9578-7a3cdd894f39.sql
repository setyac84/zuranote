
-- Drop the old restrictive SELECT policy
DROP POLICY IF EXISTS "Users can read profiles" ON public.profiles;

-- Create a new policy that allows all authenticated users to read profiles
CREATE POLICY "Users can read profiles"
ON public.profiles
FOR SELECT
USING (auth.uid() IS NOT NULL);
