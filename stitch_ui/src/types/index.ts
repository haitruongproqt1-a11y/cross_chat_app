export type ScreenType = 
  | 'chats' 
  | 'chat_detail' 
  | 'radar' 
  | 'diary' 
  | 'settings' 
  | 'call' 
  | 'login'
  | 'contacts';

export type UserRole = 'owner' | 'deputy' | 'member';

export interface User {
  id: string;
  name: string;
  handle: string;
  avatar: string;
  role?: UserRole;
  isOnline?: boolean;
  statusText?: string;
  bio?: string;
  yearOfBirth?: number;
  location?: string;
  jobTitle?: string;
  phone?: string;
  isVerified?: boolean;
}

export interface ChatItem {
  id: string;
  name: string;
  roleBadge?: {
    type: 'deputy' | 'owner';
    text: string;
  };
  lastMessage: string;
  lastMessageSender?: string;
  timestamp: string;
  unreadCount?: number;
  avatar: string;
  isOnline?: boolean;
  isPinned?: boolean;
  isMuted?: boolean;
  category: 'all' | 'unread' | 'work_school';
  customTag?: string;
}

export interface ChatMessage {
  id: string;
  senderId: string;
  senderName: string;
  senderRole?: 'owner' | 'deputy' | 'member';
  roleTag?: string;
  avatar: string;
  content?: string;
  type: 'text' | 'media_grid' | 'voice' | 'location';
  timestamp: string;
  reactions?: { emoji: string; count: number; reacted?: boolean }[];
  status?: 'sending' | 'sent' | 'delivered' | 'read';
  mediaUrls?: string[];
  mediaCaption?: string;
  voiceDuration?: string;
  voiceCurrentTime?: string;
  voiceSpeed?: string;
  locationData?: {
    title: string;
    address: string;
    distance: string;
  };
  replyTo?: {
    sender: string;
    snippet: string;
  };
}

export interface NearbyUser {
  id: string;
  name: string;
  age: number;
  gender: 'male' | 'female';
  distance: string;
  distanceMeters: number;
  activityStatus: string;
  bio: string;
  avatar: string;
  isOnline: boolean;
  radarX: number; // percentage in radar
  radarY: number; // percentage in radar
  shortCode?: string;
}

export interface FeedComment {
  id: string;
  author: string;
  avatar: string;
  content: string;
  timeAgo: string;
  likes?: number;
}

export interface FeedPost {
  id: string;
  author: string;
  authorRole?: 'owner' | 'deputy';
  roleTag?: string;
  avatar: string;
  timeAgo: string;
  privacy: 'friends' | 'public';
  content: string;
  images?: string[];
  likesCount: number;
  likedByText?: string;
  isLiked?: boolean;
  commentsCount: number;
  sharesCount: number;
  comments: FeedComment[];
  locationTag?: string;
}

export type LanguageCode = 'vi' | 'en';
