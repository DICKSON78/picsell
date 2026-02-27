const Photo = require('../models/Photo');
const User = require('../models/User');
const Transaction = require('../models/Transaction');
const aiService = require('../services/aiService');
const fs = require('fs').promises;
const path = require('path');

const photoController = {
  // Process photo with AI
  async processPhoto(req, res) {
    try {
      const user = req.user;

      if (!req.file) {
        return res.status(400).json({ error: 'No image file provided' });
      }

      // Check if user has enough credits
      if (user.credits < 1) {
        return res.status(400).json({
          error: 'Insufficient credits',
          credits: user.credits
        });
      }

      // Create photo record
      const photo = await Photo.create({
        userId: user._id,
        originalUrl: req.file.path,
        processedUrl: '',
        status: 'processing',
      });

      try {
        // Process image with AI
        const processedImageBuffer = await aiService.enhancePhoto(req.file.path);

        // Save processed image
        const processedFileName = `processed_${Date.now()}_${path.basename(req.file.path)}`;
        const processedPath = path.join('uploads', 'processed', processedFileName);

        // Ensure directory exists
        await fs.mkdir(path.join('uploads', 'processed'), { recursive: true });
        await fs.writeFile(processedPath, processedImageBuffer);

        // Update photo record
        photo.processedUrl = processedPath;
        photo.status = 'completed';
        await photo.save();

        res.json({
          success: true,
          photo: {
            id: photo._id,
            originalUrl: photo.originalUrl,
            processedUrl: photo.processedUrl,
            status: photo.status,
            createdAt: photo.createdAt,
          },
          creditsRemaining: user.credits,
        });
      } catch (error) {
        // Update photo status to failed
        photo.status = 'failed';
        await photo.save();

        throw error;
      }
    } catch (error) {
      console.error('Process Photo Error:', error);
      res.status(500).json({ error: 'Failed to process photo' });
    }
  },

  // Download processed photo (deducts credit)
  async downloadPhoto(req, res) {
    try {
      const { photoId } = req.params;
      const user = req.user;

      const photo = await Photo.findOne({ _id: photoId, userId: user._id });

      if (!photo) {
        return res.status(404).json({ error: 'Photo not found' });
      }

      if (photo.status !== 'completed') {
        return res.status(400).json({ error: 'Photo processing not completed' });
      }

      // Check if already downloaded
      if (photo.downloaded) {
        // Allow re-download without charging
        return res.sendFile(path.resolve(photo.processedUrl));
      }

      // Check credits
      if (user.credits < 1) {
        return res.status(400).json({
          error: 'Insufficient credits to download',
          credits: user.credits
        });
      }

      // Deduct credit
      user.credits -= 1;
      await user.save();

      // Mark as downloaded
      photo.downloaded = true;
      await photo.save();

      // Log transaction
      await Transaction.create({
        userId: user._id,
        type: 'usage',
        credits: -1,
        description: `Downloaded photo ${photo._id}`,
      });

      res.json({
        success: true,
        downloadUrl: photo.processedUrl,
        creditsRemaining: user.credits,
      });
    } catch (error) {
      console.error('Download Photo Error:', error);
      res.status(500).json({ error: 'Failed to download photo' });
    }
  },

  // Get user's photo history
  async getPhotoHistory(req, res) {
    try {
      const user = req.user;
      const photos = await Photo.find({ userId: user._id })
        .sort({ createdAt: -1 })
        .limit(50);

      res.json({
        success: true,
        photos: photos.map(photo => ({
          id: photo._id,
          status: photo.status,
          downloaded: photo.downloaded,
          createdAt: photo.createdAt,
          processedUrl: photo.processedUrl,
        })),
      });
    } catch (error) {
      console.error('Get Photo History Error:', error);
      res.status(500).json({ error: 'Failed to get photo history' });
    }
  },
};

module.exports = photoController;
