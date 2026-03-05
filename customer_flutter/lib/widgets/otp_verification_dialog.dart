import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/theme.dart';

class OTPVerificationDialog extends StatefulWidget {
  final String phoneNumber;
  final Function(String otp) onOTPSubmit;
  final Function() onResendOTP;
  final String? locale;

  const OTPVerificationDialog({
    super.key,
    required this.phoneNumber,
    required this.onOTPSubmit,
    required this.onResendOTP,
    this.locale,
  });

  @override
  State<OTPVerificationDialog> createState() => _OTPVerificationDialogState();
}

class _OTPVerificationDialogState extends State<OTPVerificationDialog> {
  final _otpController = TextEditingController();
  bool _isSubmitting = false;
  int _resendCountdown = 0;

  @override
  Widget build(BuildContext context) {
    final isSwahili = widget.locale == 'sw';

    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isSwahili ? 'Thibitisha Nambari' : 'Verify Your Number',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.text,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSwahili
                ? 'Tumekutumia OTP kwa nambari ${widget.phoneNumber}. Tafadhali ingiza OTP hapa chini.'
                : 'We sent an OTP to ${widget.phoneNumber}. Please enter it below.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              color: AppTheme.text,
            ),
            decoration: InputDecoration(
              hintText: '000000',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.primary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.primary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppTheme.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppTheme.background,
            ),
          ),
          const SizedBox(height: 20),
          if (_resendCountdown > 0)
            Center(
              child: Text(
                isSwahili
                    ? 'Tuma tena kwa $_resendCountdown sekunde'
                    : 'Resend in $_resendCountdown seconds',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            )
          else
            Center(
              child: TextButton(
                onPressed: _resendOTP,
                child: Text(
                  isSwahili ? 'Tuma OTP tena' : 'Resend OTP',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            isSwahili ? 'Ghairi' : 'Cancel',
            style: GoogleFonts.poppins(color: AppTheme.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitOTP,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            disabledBackgroundColor: Colors.grey[300],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSubmitting
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.surface,
                    ),
                  ),
                )
              : Text(
                  isSwahili ? 'Thibitisha' : 'Verify',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _resendOTP() {
    setState(() => _resendCountdown = 60);
    widget.onResendOTP();

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) _resendCountdown--;
        });
      }
    });
  }

  void _submitOTP() {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.locale == 'sw' ? 'Tafadhali ingiza OTP' : 'Please enter OTP',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    widget.onOTPSubmit(_otpController.text);
  }
}
