const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const photoController = require('../controllers/photoController');
const auth = require('../middleware/auth');

// Configure multer for file upload
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/original/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'photo-' + uniqueSuffix + path.extname(file.originalname));
  },
});

const upload = multer({
  storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);

    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Only JPEG, JPG, and PNG images are allowed'));
    }
  },
});

// Process photo
router.post('/process', auth, upload.single('photo'), photoController.processPhoto);

// Download processed photo
router.get('/download/:photoId', auth, photoController.downloadPhoto);

// Get photo history
router.get('/history', auth, photoController.getPhotoHistory);

module.exports = router;
