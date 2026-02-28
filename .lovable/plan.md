

## Analysis

Current architecture uses a flat `companies` table. The user wants a **holding hierarchy**: each "holding" (like SKOR BOLD!, Evindo Global Putra) is a top-level company, and its super admin/admin can create **sub-companies** underneath it. The global super admin (company_id=NULL) creates holdings via Register Company. Holdings are isolated from each other.

```text
Global Super Admin (company_id=NULL)
├── SKOR BOLD! (holding)
│   ├── Sub-company A (parent_id = SKOR)
│   └── Sub-company B (parent_id = SKOR)
└── Evindo Global Putra (holding)
    ├── Sub-company C (parent_id = Evindo)
    └── Sub-company D (parent_id = Evindo)
```

## Plan

### 1. Add `parent_id` column to `companies` table (migration)

- Add `parent_id UUID` nullable, FK to `companies(id)` with `ON DELETE CASCADE`
- Existing companies (SKOR, Evindo) remain as holdings (`parent_id = NULL`)

### 2. Create helper function `is_in_user_company_group`

A `SECURITY DEFINER` function that checks if a target `company_id` belongs to the user's holding group:
- Global (company_id IS NULL) → always true
- Scoped → true if target = own company OR target's parent_id = own company

### 3. Update Companies RLS policies

- **SELECT**: Global sees all. Scoped sees own company + companies where `parent_id = own company`
- **INSERT**: `is_admin_or_above` + scoped must set `parent_id = own company` (sub-companies only). Global can insert anything
- **UPDATE**: Super admin, scoped to own holding group
- **DELETE**: Keep current (holding-only global)

### 4. Update Projects RLS policies

Replace `company_id = get_user_company(auth.uid())` with `is_in_user_company_group(auth.uid(), company_id)` so scoped admins can create/manage projects for any sub-company in their holding.

### 5. Update `useCreateCompany` hook

Pass `parent_id` (user's own `company_id`) when creating a sub-company.

### 6. Update CompanyPage UI

- Show "Add Company" button for `isAdmin` (not just `isSuperAdmin`), since holding admins can add sub-companies
- When creating, auto-set `parent_id` to user's `company_id`
- Visual hierarchy: show holding name as header, sub-companies indented below

### 7. Update ProjectModal company dropdown

- Scoped admins see their holding company + all sub-companies in the dropdown (not just their own company)
- Global admins see all companies

### 8. Update profiles/tasks/members RLS

Replace simple `company_id = get_user_company()` checks with `is_in_user_company_group()` so scoped admins can manage members/tasks across their entire holding group.

### Technical Detail

```sql
-- Helper function
CREATE OR REPLACE FUNCTION public.is_in_user_company_group(_user_id uuid, _company_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT
    get_user_company(_user_id) IS NULL
    OR _company_id = get_user_company(_user_id)
    OR EXISTS (
      SELECT 1 FROM public.companies
      WHERE id = _company_id
        AND parent_id = get_user_company(_user_id)
    )
$$;
```

