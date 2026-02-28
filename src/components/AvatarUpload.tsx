import { useState, useRef } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { Camera } from 'lucide-react';
import { toast } from 'sonner';
import { cn } from '@/lib/utils';

interface AvatarUploadProps {
  userId: string;
  currentAvatar?: string | null;
  name: string;
  size?: 'sm' | 'md' | 'lg';
  onUploaded?: (url: string) => void;
  editable?: boolean;
}

const sizeMap = {
  sm: 'w-10 h-10 text-sm',
  md: 'w-16 h-16 text-xl',
  lg: 'w-20 h-20 text-2xl',
};

const AvatarUpload = ({ userId, currentAvatar, name, size = 'md', onUploaded, editable = true }: AvatarUploadProps) => {
  const [uploading, setUploading] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);

  const initials = name?.split(' ').map(n => n[0]).join('').slice(0, 2) || '?';

  const handleUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!file.type.startsWith('image/')) {
      toast.error('Please select an image file');
      return;
    }
    if (file.size > 2 * 1024 * 1024) {
      toast.error('Image must be under 2MB');
      return;
    }

    setUploading(true);
    try {
      const ext = file.name.split('.').pop();
      const path = `${userId}/avatar.${ext}`;

      const { error: uploadError } = await supabase.storage
        .from('avatars')
        .upload(path, file, { upsert: true });

      if (uploadError) throw uploadError;

      const { data: { publicUrl } } = supabase.storage
        .from('avatars')
        .getPublicUrl(path);

      // Add cache buster
      const url = `${publicUrl}?t=${Date.now()}`;

      await supabase.from('profiles').update({ avatar: url }).eq('id', userId);

      onUploaded?.(url);
      toast.success('Profile photo updated');
    } catch (err: any) {
      toast.error(err.message || 'Failed to upload');
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="relative group">
      {currentAvatar ? (
        <img
          src={currentAvatar}
          alt={name}
          className={cn(sizeMap[size], 'rounded-full object-cover')}
        />
      ) : (
        <div className={cn(sizeMap[size], 'rounded-full bg-primary/20 flex items-center justify-center font-semibold text-primary')}>
          {initials}
        </div>
      )}
      {editable && (
        <>
          <button
            onClick={() => fileRef.current?.click()}
            disabled={uploading}
            className={cn(
              'absolute inset-0 rounded-full bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer',
              uploading && 'opacity-100'
            )}
          >
            <Camera className="w-4 h-4 text-white" />
          </button>
          <input
            ref={fileRef}
            type="file"
            accept="image/*"
            onChange={handleUpload}
            className="hidden"
          />
        </>
      )}
    </div>
  );
};

export default AvatarUpload;
