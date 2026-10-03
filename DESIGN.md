# KINI CHAT — UI/UX Design System Specification (DESIGN.md)

This document specifies the complete design system, tokens, component states, and screen flows for **KINI CHAT**, a modern real-time cross-platform communication app for Mobile (iOS/Android) and Desktop (Windows/macOS/Linux/Web).

---

## 1. Brand Identity & Visual Vibe
- **Style Direction**: Ultra-clean, modern, tactile (combining the best of Telegram's speed, Zalo's intuitive layout, and Apple Messages' smooth aesthetics).
- **Design Metaphor**: Fluid rounded surfaces, glassmorphic floating bars, soft micro-shadows, and high-contrast typography.
- **Accessibility**: Strict WCAG AA contrast compliance for both Light Mode and Dark Mode.

---

## 2. Color System & Design Tokens

### Primary & Accent Colors
| Token Name | Hex Code | Purpose |
|------------|----------|---------|
| `color-primary` | `#0284C7` (Sky 600) | Main action buttons, active tab indicators, link text |
| `color-primary-dark` | `#0369A1` (Sky 700) | Pressed button state, desktop navigation headers |
| `color-secondary-mint` | `#10B981` (Emerald 500) | Online presence status dot, success toasts |
| `color-accent-gold` | `#F59E0B` (Amber 500) | Group Owner (Trưởng nhóm 👑) badge, pinned message pin |
| `color-deputy-blue` | `#3B82F6` (Blue 500) | Group Deputy (Phó nhóm 🛡️) badge |
| `color-danger` | `#DC2626` (Red 600) | Swipe-to-delete action, kick member, exit group |

### Light Mode Surfaces & High-Contrast Typography
| Token Name | Hex Code | Usage |
|------------|----------|-------|
| `surface-bg-light` | `#F8FAFC` (Slate 50) | Global scaffold background |
| `surface-card-light` | `#FFFFFF` (Pure White) | Card containers, list items, input fields |
| `text-primary-light` | `#0F172A` (Slate 900) | Main titles, user names, unread message text (sharp & dark) |
| `text-secondary-light`| `#1E293B` (Slate 800) | Body message text, subtitle text |
| `text-muted-light` | `#475569` (Slate 600) | Timestamps, read receipts, member counts |
| `border-subtle-light` | `#E2E8F0` (Slate 200) | Dividers, card borders, message bubble outlines |

### Dark Mode Surfaces
| Token Name | Hex Code | Usage |
|------------|----------|-------|
| `surface-bg-dark` | `#0F172A` (Slate 900) | Scaffold background |
| `surface-card-dark` | `#1E293B` (Slate 800) | Cards, bottom navigation, top app bar |
| `text-primary-dark` | `#F8FAFC` (Slate 50) | Main titles and active text |
| `text-secondary-dark`| `#94A3B8` (Slate 400) | Subtitles and timestamps |
| `border-subtle-dark` | `#334155` (Slate 700) | Dividers and borders |

---

## 3. Typography Scale
- **Display Large**: 24px, Bold (w700), Line Height: 32px
- **Title Large**: 18px, Bold (w700), Line Height: 24px (App bar titles, contact headers)
- **Title Medium**: 15px, Semi-Bold (w600), Line Height: 20px (Room names, sender names)
- **Body Large**: 15px, Regular (w400), Line Height: 22px (Message content)
- **Body Medium**: 13px, Medium (w500), Line Height: 18px (Chat previews, sub-descriptions)
- **Caption / Meta**: 11px, Semi-Bold (w600), Line Height: 14px (Timestamps, status badges)

---

## 4. Key UI Components & Interactions

### 4.1. Chat List Item (`ChatListView`)
- **Normal State**: 72px item height with 48px rounded circular avatar, online indicator badge on bottom-right edge.
- **Swipe-to-Delete Action (Zalo-style)**:
  - Drag direction: End-to-Start (Swipe Left).
  - Background reveals vibrant Red (`#DC2626`) container with a delete trash icon and prominent bold label **"XÓA"**.
  - Triggers a confirmation modal before permanent message clearing.
- **Long-Press Menu**:
  - Modal bottom sheet displaying avatar, room name, and options: "Cài đặt nhóm", "Đánh dấu đã đọc", and red "Xóa cuộc trò chuyện".

### 4.2. Message Bubbles (`MessageBubble`)
- **Layout**:
  - Sent Messages (`isMe`): Align right, customized theme background (or Sky Blue gradient), 18px radius with 4px tail corner on bottom right.
  - Received Messages: Align left, soft light-grey/white surface, 18px radius with 4px tail corner on bottom left.
- **Ownership & Custom Bubble Themes**:
  - 20 collectible themes (e.g. Cloud Bunny 🐰, Capybara 🦫, Dino 🦖, Sakura 🌸).
  - Bubbles reflect the **sender's chosen theme** with corner decorative sticker stamps.
- **Interactive Elements**:
  - Emoji reactions tray (👍, ❤️, 😂, 😮, 😢, 🙏).
  - Reply preview bar linking back to original message.
  - Pinned message banner at top of chat room.

### 4.3. Group Settings Screen (`GroupSettingsScreen`)
- **Header**: Circular group avatar (with camera edit overlay for admins), group name with edit button, member & deputy counter (`X thành viên • Y/10 Phó nhóm`).
- **Role Badges**:
  - 👑 **Trưởng nhóm**: Amber badge (`#F59E0B`) with gold border.
  - 🛡️ **Phó nhóm**: Sky Blue badge (`#0284C7`) with soft blue background (capped at 10 deputies).
  - **Thành viên**: Standard member item.
- **Admin Controls**:
  - Switch: *"Chỉ Trưởng/Phó nhóm được gửi tin nhắn"* (locks chat input for non-admins).
  - Switch: *"Chỉ Trưởng/Phó nhóm được thêm thành viên"*.
- **Danger Zone Button**:
  - Red button: *"Rời khỏi nhóm"* / *"Rời nhóm & Trao lại Key"*.
  - Dialog allows picking a successor member OR auto-randomly assigning an existing member.

### 4.4. Multimedia & Embedded Social Viewer
- **Multi-Media Grid**: Zalo-style adaptive grid displaying 1 to 10 photos or videos with full-screen swipeable preview gallery.
- **TikTok & LIVE Viewer**: Full-screen short-video stream with in-app liking, commenting, and direct sharing to any chat room.

---

## 5. Screen Map
```
[App Entry]
   │
   ├─► [LoginScreen] / [RegisterScreen] (Auto-login credential persistence)
   │
   └─► [HomeScreen] (Responsive: Bottom Navigation on Mobile, Split Sidebar on Desktop)
         │
         ├─► [ChatListView] (Messages Tab with Swipe-to-Delete & Search)
         │     │
         │     └─► [ChatDetailScreen] (Real-time messages, calls, wallpaper, themes)
         │           │
         │           └─► [GroupSettingsScreen] (Zalo group management & Key transfer)
         │
         ├─► [ContactsView] (Friends, add friend by ID/Phone, QR code, nearby GPS)
         │
         ├─► [UserWallScreen] (Social Feed, posts, photos, comments)
         │
         ├─► [TikTokViewerScreen] (Embedded TikTok & LIVE streams)
         │
         └─► [SettingsView] (Account profile, bubble theme picker, OTA updates)
```
