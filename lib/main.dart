import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_tools/qr_code_tools.dart';
import 'package:hive/hive.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);

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
  Barcode? result;
  QRViewController? controller;
  bool isLoading = false;

  late Box<String> qrDataBox;

  @override
  void initState() {
    super.initState();
    _initializeHiveBox();
  }

  Future<void> _initializeHiveBox() async {
    qrDataBox = await Hive.openBox<String>('qrData');
  }

  @override
  void dispose() {
    controller?.dispose();
    Hive.close();
    super.dispose();
  }

  void _pickImageAndDecode() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          isLoading = true;
        });

        String? qrData = await QrCodeToolsPlugin.decodeFrom(image.path);

        setState(() {
          isLoading = false;
        });

        if (qrData != null) {
          _saveQRData(qrData);
          _showSuccessAnimation();
        } else {
          _showErrorDialog('No QR code found in the image.');
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Failed to decode QR code from image.');
    }
  }

  void _saveQRData(String qrData) {
    qrDataBox.add(qrData);
    setState(() {
      result = Barcode(qrData, BarcodeFormat.qrcode, []);
    });
  }

  void _shareQRData(String data) {
    Share.share(data);
  }

  void _showSuccessAnimation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('QR Code Decoded Successfully!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorDialog(String message) {
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
        centerTitle: true,
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
                  formatsAllowed: const [
                    BarcodeFormat.qrcode,
                    BarcodeFormat.code128,
                    BarcodeFormat.code39,
                    BarcodeFormat.dataMatrix,
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    (result != null)
                        ? Column(
                            children: [
                              Text(
                                'Data: ${result!.code}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () => _shareQRData(result!.code!),
                                child: const Text('Share QR Data'),
                              ),
                            ],
                          )
                        : const Text(
                            'Scan a code or upload an image',
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

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
      _saveQRData(scanData.code!);
      _showSuccessAnimation();
    });
  }
}
