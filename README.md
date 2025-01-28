# OTP-SPAMMER

Make it executable: chmod +x otp_sender.sh
Run it with parameters: ./otp_sender.sh --mobile 1234567890 --threads 3
The script accepts the same command-line arguments as the Python version:
--mobile: Target mobile number (required)
--threads: Number of concurrent threads (default: 1)
--min-delay: Minimum delay between requests (default: 2)
--max-delay: Maximum delay between requests (default: 5)
