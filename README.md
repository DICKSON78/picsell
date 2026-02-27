# 📸 DukaSell Studio - AI-Powered Passport Photo App

Professional passport & business photos powered by AI. Built with React Native (Expo) and Express.js.

## ✨ Features

- 🎨 **AI Background Removal** - Automatic background removal with studio-quality white background
- 📸 **Camera & Gallery Support** - Take new photos or upload existing ones
- 💡 **Studio Enhancement** - Professional lighting and color correction
- 💳 **Credits System** - Fair pay-per-use model with multiple packages
- 📱 **Cross-Platform** - Works on iOS, Android, and Web
- 🔐 **Google OAuth** - Secure authentication
- 📊 **History & Analytics** - Track your photos and credit usage
- 🎨 **Vibrant UI** - Modern, clean design with smooth animations

## 🏗️ Tech Stack

### Frontend (Mobile)
- React Native with Expo
- Expo Router for navigation
- Expo Auth Session for Google OAuth
- Expo Image Picker for camera/gallery
- Axios for API calls
- AsyncStorage for local data

### Backend
- Express.js
- MongoDB with Mongoose
- Google OAuth Library
- JWT for authentication
- Multer for file uploads
- Stripe for payments
- Remove.bg API for AI processing

## 📋 Prerequisites

Before you begin, ensure you have:

- Node.js 18+ installed
- MongoDB installed and running
- Expo CLI (`npm install -g expo-cli`)
- iOS Simulator (Mac) or Android Emulator
- Google Cloud Console account
- Remove.bg API account
- Stripe account (for payments)

## 🚀 Setup Instructions

### 1. Clone and Install

```bash
cd dukasell
npm install
```

### 2. Set Up Google OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project
3. Enable Google+ API
4. Create OAuth 2.0 credentials:
   - For **Web** (Backend):
     - Authorized redirect URIs: `http://localhost:5000/auth/google/callback`
   - For **iOS**:
     - Get the bundle identifier from `app.json`
   - For **Android**:
     - Get SHA-1 fingerprint: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey`
5. Download credentials and note:
   - Client ID
   - Client Secret

### 3. Get Remove.bg API Key

1. Go to [Remove.bg](https://www.remove.bg/api)
2. Sign up for an account
3. Get your API key from the dashboard
4. Free tier: 50 API calls/month
5. Paid plans available for production

### 4. Set Up Stripe

1. Go to [Stripe Dashboard](https://dashboard.stripe.com)
2. Get your API keys:
   - Secret Key
   - Publishable Key
3. For testing, use test mode keys

### 5. Configure Backend

Edit `backend/.env` file with your actual keys:

```env
PORT=5000
MONGODB_URI=mongodb://localhost:27017/dukasell
JWT_SECRET=your_super_secret_jwt_key_here

# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id_here
GOOGLE_CLIENT_SECRET=your_google_client_secret_here

# Remove.bg API
REMOVE_BG_API_KEY=your_remove_bg_api_key_here

# Stripe
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key
STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable_key

# Frontend URL
FRONTEND_URL=http://localhost:8081
```

### 6. Configure Frontend

Update `app/login.js` with your Google Client ID (line 29):

```javascript
const [request, response, promptAsync] = Google.useIdTokenAuthRequest({
  clientId: 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com', // Replace this
});
```

### 7. Start MongoDB

```bash
# If using MongoDB locally
mongod
```

Or use MongoDB Atlas:
1. Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Create a cluster
3. Get connection string
4. Update `MONGODB_URI` in `backend/.env`

## 🏃 Running the App

### Option 1: Run Backend and Frontend Together

```bash
npm run dev
```

### Option 2: Run Separately

**Terminal 1 - Backend:**
```bash
npm run backend
```

**Terminal 2 - Frontend:**
```bash
npm start
```

### Running on Specific Platforms

```bash
# iOS
npm run ios

# Android
npm run android

# Web
npm run web
```

## 📱 App Screens

1. **Login Screen** - Google OAuth authentication with welcome bonus info
2. **Home Screen** - Main dashboard with camera/gallery options and sidebar navigation
3. **Editor Screen** - View original vs processed photo, download with credits
4. **Credits Screen** - Purchase credit packages with multiple pricing options
5. **History Screen** - View photo history and transaction records

## 🎨 Color Scheme

The app uses a vibrant, studio-quality color scheme:

- **Primary**: Electric Purple (#6C5CE7)
- **Accent**: Vibrant Cyan (#00D2FF)
- **Background**: Dark Studio (#0F0F1E)
- **Success**: Bright Green (#00E676)
- **Gold**: Premium Gold (#FFD700)

## 💰 Credits System

- New users get **5 free credits** on signup
- Each photo download costs **1 credit**
- Photo processing is free (only download costs credits)
- Credits never expire

### Credit Packages
- 10 Credits - $4.99
- 25 Credits - $9.99 (20% off) - POPULAR
- 50 Credits - $17.99 (28% off)
- 100 Credits - $29.99 (40% off)

## 🔐 API Endpoints

### Authentication
- `POST /api/auth/google-signin` - Google OAuth login
- `GET /api/auth/me` - Get current user

### Photos
- `POST /api/photos/process` - Process photo with AI
- `GET /api/photos/download/:photoId` - Download processed photo
- `GET /api/photos/history` - Get photo history

### Credits
- `GET /api/credits/packages` - Get credit packages
- `POST /api/credits/create-payment` - Create payment intent
- `POST /api/credits/confirm-payment` - Confirm payment
- `GET /api/credits/transactions` - Get transaction history

## 🚨 Troubleshooting

### MongoDB Connection Error
- Ensure MongoDB is running: `mongod`
- Check connection string in `backend/.env`

### Google OAuth Not Working
- Verify Client ID in `app/login.js`
- Check OAuth credentials in Google Cloud Console
- Ensure redirect URIs are correct

### Image Processing Failed
- Check Remove.bg API key
- Verify API quota (free tier: 50/month)
- Check internet connection

## 📝 Next Steps for Production

- Set up proper file storage (AWS S3, Cloudinary)
- Implement actual Stripe payment flow with SDK
- Add image optimization and caching
- Set up error tracking (Sentry)
- Add analytics (Firebase, Mixpanel)
- Implement rate limiting
- Add comprehensive tests
- Configure production environment variables
- Set up CDN for images
- Add email/push notifications

## 📄 License

This project is private and proprietary.

---

**Built with ❤️ for professional passport photos**

---

## 🛠️ Admin Panel

DukaSell Studio now includes a comprehensive admin panel for managing your application and users.

### 🎯 Admin Panel Features

- **Dashboard**: Real-time statistics and overview
- **User Management**: View, search, and manage all users
- **User Analytics**: Detailed user statistics and activity tracking
- **Analytics Dashboard**: Charts showing user growth and credit distribution
- **System Settings**: Configure application settings and API keys
- **Secure Authentication**: Admin login system with session management

### 🚀 Quick Setup for Admin Panel

1. **Install admin dependencies:**
```bash
cd admin && npm install
```

2. **Create admin account:**
```bash
npm run admin-setup
```

3. **Start admin panel:**
```bash
npm run admin
```

4. **Access admin panel:**
- URL: `http://localhost:3001`
- Default login: `admin` / `admin123`

### 📱 Admin Panel Usage

#### Dashboard
- View total users, active users, credits in system
- See recent user registrations
- Monitor photo processing statistics

#### User Management
- View all users with pagination
- Search and filter users
- View detailed user profiles
- Activate/deactivate users
- Track user activity and credits

#### Analytics
- User growth charts over time
- Credit distribution analysis
- Revenue and usage statistics
- Visual insights with Chart.js

#### Settings
- Configure welcome bonus credits
- Set photo processing costs
- Manage credit packages
- Update API keys
- System maintenance controls

### 🎨 Admin Panel Design

The admin panel features the same modern design as your main application:
- **Color Scheme**: Electric Purple (#6C5CE7) and Vibrant Cyan (#00D2FF)
- **Dark Theme**: Professional dark studio background
- **Responsive Design**: Works on desktop and tablet
- **Modern UI**: Clean, intuitive interface with smooth transitions

### 🔐 Security Features

- Session-based authentication
- Secure password hashing with bcrypt
- MongoDB session storage
- Admin role management
- Automatic logout on inactivity

### 📊 Available Scripts

```bash
# Start admin panel only
npm run admin

# Create admin account
npm run admin-setup

# Start everything (backend, frontend, admin)
npm run dev-all

# Start backend and frontend (original)
npm run dev
```

### 🗂️ Admin Panel Structure

```
admin/
├── server.js              # Main admin server
├── package.json           # Admin dependencies
├── .env                   # Admin environment variables
├── models/                # Admin-specific models
│   ├── Admin.js          # Admin user model
│   └── User.js           # User management model
├── routes/                # Admin routes
│   ├── auth.js           # Authentication routes
│   └── admin.js          # Main admin routes
├── middleware/            # Authentication middleware
├── views/                 # EJS templates
│   ├── login.ejs         # Admin login page
│   ├── dashboard.ejs    # Dashboard view
│   ├── users.ejs         # User management
│   ├── user-details.ejs  # User details
│   ├── analytics.ejs     # Analytics dashboard
│   └── settings.ejs      # System settings
└── scripts/
    └── create-admin.js   # Setup script
```

**Admin panel is now ready! 🎉 You can manage your entire application and users through this powerful interface.**
