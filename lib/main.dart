import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_tools/qr_code_tools.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QRCodeScannerPage(),
    );
  }
}

class QRCodeScannerPage extends StatefulWidget {
  @override
  _QRCodeScannerPageState createState() => _QRCodeScannerPageState();
}

class _QRCodeScannerPageState extends State<QRCodeScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  Barcode? scannedResult;
  bool isLoading = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController qrController) {
    setState(() {
      controller = qrController;
    });

    qrController.scannedDataStream.listen((Barcode scanData) {
      setState(() {
        scannedResult = scanData;
      });
    });
  }

  Future<void> _pickImageAndDecode() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        isLoading = true;
      });

      try {
        final qrData = await QrCodeToolsPlugin.decodeFrom(image.path);

        setState(() {
          isLoading = false;
          if (qrData != null) {
            scannedResult = Barcode(qrData, BarcodeFormat.qrcode, []);
          } else {
            _showError('No QR code found in the selected image.');
          }
        });
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        _showError('Failed to decode QR code: $e');
      }
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Scanner'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 5,
                child: QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: Colors.green,
                    borderRadius: 10,
                    borderLength: 20,
                    borderWidth: 5,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (scannedResult != null)
                      Text(
                        'Scanned: ${scannedResult!.code}',
                        style: const TextStyle(fontSize: 16),
                      )
                    else
                      const Text(
                        'Scan a QR code or upload an image',
                        style: TextStyle(fontSize: 16),
                      ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _pickImageAndDecode,
                      child: const Text('Upload QR Code Image'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
