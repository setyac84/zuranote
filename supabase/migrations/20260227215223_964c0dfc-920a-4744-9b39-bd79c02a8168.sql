
-- Create storage bucket for task images
INSERT INTO storage.buckets (id, name, public) VALUES ('task-images', 'task-images', true);

-- Allow authenticated users to upload images
CREATE POLICY "Authenticated users can upload task images"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'task-images' AND auth.role() = 'authenticated');

-- Allow public read access
CREATE POLICY "Task images are publicly readable"
ON storage.objects FOR SELECT
USING (bucket_id = 'task-images');

-- Allow authenticated users to delete their uploads
CREATE POLICY "Authenticated users can delete task images"
ON storage.objects FOR DELETE
USING (bucket_id = 'task-images' AND auth.role() = 'authenticated');
