

## Plan: Add Company Entity + Enhanced Project CRUD

### 1. Add Company type and mock data
**`src/types/index.ts`** — Add `Company` interface with `id`, `name`, `description`, `created_at`

**`src/data/mock.ts`** — Add `mockCompanies` array, add `company_name` field reference. Add `start_date`, `end_date`, `priority` fields to `Project` interface.

### 2. Update Project interface
**`src/types/index.ts`** — Extend `Project` with:
- `start_date: string`
- `end_date: string`  
- `priority: TaskPriority`

Update `mockProjects` in mock.ts with these new fields and company references.

### 3. Create Project CRUD modal
**`src/components/ProjectModal.tsx`** — New component with:
- Form fields: Company (dropdown from mockCompanies), Project Name, Description, Start Date, End Date, Priority (dropdown), Status (dropdown)
- Three modes: **view**, **edit**, **create**
- Buttons: Save, Edit, Delete (with confirmation)
- Opens from Projects page and Dashboard

### 4. Update Projects page with Create button
**`src/pages/Projects.tsx`** — Add "Tambah Project" button (admin only), integrate ProjectModal for create/view/edit. Manage local state for adding/editing/deleting projects.

### 5. Update ProjectCard to show new fields
**`src/components/ProjectCard.tsx`** — Display company name, priority badge, start/end dates.

### 6. Update Dashboard
**`src/pages/Dashboard.tsx`** — When clicking on a project-related stat, open relevant view. Show company info where relevant.

### Files to create
- `src/components/ProjectModal.tsx`

### Files to modify
- `src/types/index.ts`
- `src/data/mock.ts`
- `src/pages/Projects.tsx`
- `src/components/ProjectCard.tsx`
- `src/pages/Dashboard.tsx`

