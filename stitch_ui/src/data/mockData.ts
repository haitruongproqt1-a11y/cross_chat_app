import { ChatItem, ChatMessage, NearbyUser, FeedPost, User } from '../types';

export const CURRENT_USER: User = {
  id: 'user_nam',
  name: 'Trần Hoàng Nam',
  handle: '@hoangnam_kini',
  avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
  role: 'owner',
  isOnline: true,
  statusText: 'Đang hoạt động',
  bio: 'Lead Mobile Engineer @ KINI CHAT • Đam mê công nghệ & trải nghiệm giao diện tối giản, tức thì.',
  yearOfBirth: 1998,
  location: 'Hà Nội',
  jobTitle: 'Kỹ sư phần mềm',
  phone: '098****123',
  isVerified: true
};

export const INITIAL_CHATS: ChatItem[] = [
  {
    id: 'kini_core',
    name: 'KINI Core Engineering',
    roleBadge: {
      type: 'owner',
      text: 'Key chính'
    },
    lastMessage: 'Văn phòng KINI CHAT - Q. Cầu Giấy, Hà Nội',
    lastMessageSender: 'Thu Hà',
    timestamp: '10:35',
    unreadCount: 3,
    avatar: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=400&q=80',
    isOnline: true,
    isPinned: true,
    category: 'work_school',
    customTag: 'Nhóm kỹ thuật lõi'
  },
  {
    id: 'kini_dev_team',
    name: 'KINI Developer Team',
    roleBadge: {
      type: 'deputy',
      text: '2 Phó Nhóm'
    },
    lastMessage: 'Nam: Đã cập nhật xong tính năng trao Key...',
    lastMessageSender: 'Nam',
    timestamp: '10:45',
    unreadCount: 1,
    avatar: 'https://images.unsplash.com/photo-1556761175-5973dc0f32e7?auto=format&fit=crop&w=400&q=80',
    isOnline: true,
    isPinned: true,
    category: 'work_school'
  },
  {
    id: 'thu_ha',
    name: 'Nguyễn Thu Hà (Thiết kế UI/UX)',
    lastMessage: 'File thiết kế mới toanh, Cậu Check lại file...',
    timestamp: '09:12',
    avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80',
    isOnline: true,
    isPinned: false,
    category: 'unread'
  },
  {
    id: 'le_minh_tuan',
    name: 'Lê Minh Tuấn',
    roleBadge: {
      type: 'deputy',
      text: 'Phó nhóm 🛡️'
    },
    lastMessage: 'Hôm nay chuẩn bị deploy production v2.4 nhé anh em!',
    timestamp: '08:50',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
    isOnline: true,
    category: 'work_school'
  },
  {
    id: 'linh_tran',
    name: 'Linh Trần',
    roleBadge: {
      type: 'deputy',
      text: 'Phó nhóm'
    },
    lastMessage: 'Em đang chia sẻ màn hình Sprint Review...',
    timestamp: 'Hôm qua',
    avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=400&q=80',
    isOnline: false,
    category: 'all'
  },
  {
    id: 'capybara_chill',
    name: 'Capybara Chill 🐾',
    lastMessage: 'Dạ rõ ạ Trưởng nhóm! Em đã chuẩn bị sẵn file...',
    timestamp: 'Thứ 4',
    avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=400&q=80',
    isOnline: true,
    category: 'all'
  }
];

export const STORIES_DATA = [
  { id: '1', name: 'Nam Cho', avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=200&q=80', isLive: false, unread: true },
  { id: '2', name: 'Tuấn Anh', avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80', isLive: true, unread: true },
  { id: '3', name: 'Thu Hà', avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=200&q=80', isLive: false, unread: true },
  { id: '4', name: 'Dũng Đặng', avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80', isLive: false, unread: false },
];

export const GROUP_CHAT_MESSAGES: ChatMessage[] = [
  {
    id: 'm1',
    senderId: 'user_nam',
    senderName: 'Trần Hoàng Nam',
    senderRole: 'owner',
    roleTag: 'Trưởng nhóm',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
    type: 'text',
    content: 'Chào cả nhóm! Hôm nay mình bật chế độ chỉ Trưởng và Phó nhóm được chat để tổng kết sprint nhé. Mọi người theo dõi sát timeline bên dưới.',
    timestamp: '10:30',
    reactions: [
      { emoji: '👍', count: 4, reacted: true },
      { emoji: '❤️', count: 6, reacted: true },
      { emoji: '🔥', count: 3, reacted: false }
    ],
    status: 'read'
  },
  {
    id: 'm2',
    senderId: 'user_capy',
    senderName: 'Capybara Chill',
    roleTag: 'Capybara Chill',
    avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=400&q=80',
    type: 'text',
    content: 'Dạ rõ ạ Trưởng nhóm! Em đã chuẩn bị sẵn file demo tính năng tìm quanh đây GPS và video call chia sẻ màn hình rồi ạ.',
    timestamp: '10:32',
    reactions: [
      { emoji: '❤️', count: 2, reacted: false }
    ],
    status: 'delivered'
  },
  {
    id: 'm3',
    senderId: 'user_nam',
    senderName: 'Trần Hoàng Nam',
    senderRole: 'owner',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
    type: 'media_grid',
    mediaCaption: '4 hình ảnh mockup KINI v2.4',
    mediaUrls: [
      'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1551650975-87deedd944c3?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1531403009284-440f080d1e12?auto=format&fit=crop&w=400&q=80'
    ],
    timestamp: '10:33',
    status: 'sent'
  },
  {
    id: 'm4',
    senderId: 'user_nam',
    senderName: 'Trần Hoàng Nam',
    senderRole: 'owner',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
    type: 'voice',
    voiceDuration: '1:15',
    voiceCurrentTime: '0:42',
    voiceSpeed: '1.5x',
    timestamp: '10:34',
    status: 'sent'
  },
  {
    id: 'm5',
    senderId: 'thu_ha',
    senderName: 'Nguyễn Thu Hà',
    avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80',
    type: 'location',
    locationData: {
      title: 'Văn phòng KINI CHAT',
      address: 'Q. Cầu Giấy, Hà Nội',
      distance: 'Cách bạn 350m'
    },
    timestamp: '10:35',
    status: 'read'
  }
];

export const NEARBY_USERS: NearbyUser[] = [
  {
    id: 'nb1',
    name: 'Hoàng Nam',
    age: 26,
    gender: 'male',
    distance: '120m',
    distanceMeters: 120,
    activityStatus: 'Đang hoạt động gần Keangnam',
    bio: 'Lập trình viên Mobile & KINI lover. Thích cà phê giao lưu công nghệ cuối tuần nhé!',
    avatar: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=300&q=80',
    isOnline: true,
    radarX: 68,
    radarY: 30
  },
  {
    id: 'nb2',
    name: 'Minh Anh',
    age: 23,
    gender: 'female',
    distance: '450m',
    distanceMeters: 450,
    activityStatus: 'Vừa mới ghé thăm Discovery Complex',
    bio: 'Designer UX/UI tại Keangnam Landmark. Thích nghe nhạc Indie, chụp film và đi dạo...',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
    isOnline: true,
    radarX: 74,
    radarY: 76
  },
  {
    id: 'nb3',
    name: 'Quang Huy',
    age: 28,
    gender: 'male',
    distance: '1.2km',
    distanceMeters: 1200,
    activityStatus: 'Hoạt động 15 phút trước',
    bio: 'Tìm bạn giao lưu bóng đá mini sân cỏ nhân tạo thứ 4 hàng tuần quanh khu vực Cầu Giấy...',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80',
    isOnline: false,
    radarX: 30,
    radarY: 38
  },
  {
    id: 'nb4',
    name: 'Linh Đặng',
    age: 25,
    gender: 'female',
    distance: '2.1km',
    distanceMeters: 2100,
    activityStatus: 'Hoạt động hôm nay',
    bio: 'Cộng đồng công nghệ KINI. Luôn hào hứng với các dự án mã nguồn mở.',
    avatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=300&q=80',
    isOnline: true,
    radarX: 36,
    radarY: 75,
    shortCode: 'LD'
  }
];

export const FEED_POSTS: FeedPost[] = [
  {
    id: 'p1',
    author: 'Lê Minh Tuấn',
    authorRole: 'deputy',
    roleTag: 'Phó nhóm',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80',
    timeAgo: '25 phút trước',
    privacy: 'friends',
    content: 'Hôm nay chính thức hoàn thiện bản build KINI CHAT v2.4 đa nền tảng! Trải nghiệm gọi video HD và radar quanh đây siêu mượt mà mọi người nhé 🚀🎉',
    images: [
      'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?auto=format&fit=crop&w=600&q=80',
      'https://images.unsplash.com/photo-1531403009284-440f080d1e12?auto=format&fit=crop&w=600&q=80',
      'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=600&q=80'
    ],
    likesCount: 28,
    likedByText: 'Trần Nam và 27 người khác',
    isLiked: true,
    commentsCount: 12,
    sharesCount: 4,
    comments: [
      {
        id: 'c1',
        author: 'Nguyễn Mai Anh',
        avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
        content: 'Animation radar chuyển cảnh mượt dã man anh Tuấn ơi, test trên iPhone 15 Pro Max 120Hz siêu phê! 🔥',
        timeAgo: '15 ph'
      },
      {
        id: 'c2',
        author: 'Đặng Quang Huy',
        avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
        content: 'Chúc mừng cả team Mobile! Chuẩn bị deploy production luôn chiều nay nhé 👏',
        timeAgo: '8 ph'
      }
    ]
  },
  {
    id: 'p2',
    author: 'Thu Hà',
    avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=300&q=80',
    timeAgo: '2 giờ trước',
    privacy: 'public',
    content: 'Trời thu Hà Nội tuyệt đẹp tại Hồ Tây ☕🌅 Không khí se lạnh buổi sáng làm một ly cà phê muối ngắm mặt hồ thì còn gì bằng.',
    locationTag: 'Hồ Tây, Hà Nội',
    images: [
      'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=800&q=80'
    ],
    likesCount: 54,
    isLiked: false,
    commentsCount: 19,
    sharesCount: 2,
    comments: []
  }
];

export const THEME_BUBBLES = [
  { id: 'capybara', name: 'Capybara Chill', icon: '🐾', preview: 'Xin chào! 👋', color: '#0284C7' },
  { id: 'cloud_bunny', name: 'Cloud Bunny', icon: '🐰', preview: 'Hôm nay thế nào?', color: '#8B5CF6' },
  { id: 'minimal_slate', name: 'Minimal Slate', icon: '⚡', preview: 'Tin nhắn E2EE', color: '#0F172A' },
  { id: 'emerald_speed', name: 'Emerald Speed', icon: '🍃', preview: 'Mã hóa đa tầng', color: '#059669' }
];
