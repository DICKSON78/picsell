const FormData = require('form-data');
const axios = require('axios');
const fs = require('fs');

class AIService {
  constructor() {
    this.apiKey = process.env.REMOVE_BG_API_KEY;
    this.apiUrl = 'https://api.remove.bg/v1.0/removebg';
  }

  async removeBackground(imagePath, options = {}) {
    try {
      const {
        type = 'auto', // auto, person, product, car
        bgColor = '#FFFFFF', // White background (studio default)
        size = 'auto',
      } = options;

      const formData = new FormData();
      formData.append('image_file', fs.createReadStream(imagePath));
      formData.append('size', size);
      formData.append('format', 'png');
      formData.append('type', type); // Auto-detect or specific type
      formData.append('bg_color', bgColor); // Customizable background

      const response = await axios.post(this.apiUrl, formData, {
        headers: {
          ...formData.getHeaders(),
          'X-Api-Key': this.apiKey,
        },
        responseType: 'arraybuffer',
      });

      return response.data;
    } catch (error) {
      console.error('AI Service Error:', error.response?.data || error.message);
      throw new Error('Failed to process image with AI');
    }
  }

  async enhancePhoto(imagePath, options = {}) {
    // Enhanced photo processing with studio-quality background removal
    // Works for all photo types: portraits, products, items, etc.
    return await this.removeBackground(imagePath, {
      type: options.type || 'auto', // Auto-detect photo type
      bgColor: options.bgColor || '#FFFFFF', // Studio white background
      size: options.size || 'auto',
    });
  }
}

module.exports = new AIService();
