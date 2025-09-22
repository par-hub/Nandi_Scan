# 📱 Flutter Integration Guide for Cattle Breed FastAPI

This guide shows how to connect your Flutter app to the FastAPI server in `Deploy/app.py`.

Server endpoints:
- GET `/` - API status
- GET `/health` - Health check
- GET `/breeds` - List of supported breeds
- GET `/model/info` - Model and API info
- POST `/predict` - Single image prediction (multipart file upload)
- POST `/predict/batch` - Multiple images prediction (limit 10)

---

## 1) Run the FastAPI server

Windows PowerShell (from project root):

```powershell
python -m pip install -r requirements.txt
python .\Deploy\app.py
```

The server will start at:
- Local: http://127.0.0.1:8000
- Docs: http://127.0.0.1:8000/docs

If you need to access from a phone/emulator on the same network, replace `127.0.0.1` with your PC's LAN IP (e.g., `192.168.1.25`).

---

## 2) Flutter dependencies

Add these to `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.2.2
  image_picker: ^1.1.2
  dio: ^5.6.0 # optional, for progress upload
```

Run:

```bash
flutter pub get
```

---

## 3) API service (Dart)

Create `lib/services/api_service.dart` in your Flutter project:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this base URL to your server IP/port
  // For Android emulator: use http://10.0.2.2:8000
  // For iOS simulator: use http://127.0.0.1:8000
  // For real device: use your PC's LAN IP, e.g., http://192.168.1.25:8000
  final String baseUrl;

  ApiService({required this.baseUrl});

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, dynamic>> health() async {
    final resp = await http.get(_uri('/health'));
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> modelInfo() async {
    final resp = await http.get(_uri('/model/info'));
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<List<String>> breeds() async {
    final resp = await http.get(_uri('/breeds'));
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final List list = data['breeds'] as List;
    return list.map((e) => e.toString()).toList();
  }

  Future<Map<String, dynamic>> predict(File image) async {
    final request = http.MultipartRequest('POST', _uri('/predict'))
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw HttpException('Prediction failed: ${response.statusCode} ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
```

---

## 4) Simple UI to pick an image and call API

Create `lib/pages/predict_page.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class PredictPage extends StatefulWidget {
  final ApiService api;
  const PredictPage({super.key, required this.api});

  @override
  State<PredictPage> createState() => _PredictPageState();
}

class _PredictPageState extends State<PredictPage> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _pickImage() async {
    setState(() { _error = null; _result = null; });
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (picked != null) {
      setState(() { _image = File(picked.path); });
    }
  }

  Future<void> _predict() async {
    if (_image == null) return;
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final res = await widget.api.predict(_image!);
      setState(() { _result = res; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cattle Breed Prediction')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Pick Image'),
            ),
            const SizedBox(height: 12),
            if (_image != null)
              AspectRatio(
                aspectRatio: 1,
                child: Image.file(_image!, fit: BoxFit.cover),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loading || _image == null ? null : _predict,
              icon: const Icon(Icons.cloud_upload),
              label: _loading ? const Text('Predicting...') : const Text('Predict'),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_result != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Breed: ${_result!['prediction']['breed']}', style: Theme.of(context).textTheme.titleMedium),
                      Text('Confidence: ${_result!['prediction']['confidence']}%'),
                      const SizedBox(height: 8),
                      const Text('Top Predictions:'),
                      const SizedBox(height: 6),
                      for (final p in _result!['top_predictions'] as List)
                        Text('- ${p['breed']} (${p['confidence']}%)'),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
```

Wire it in `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'pages/predict_page.dart';

void main() {
  // Change the baseUrl as per your environment.
  const baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:8000', // Android emulator default
  );
  runApp(MyApp(api: ApiService(baseUrl: baseUrl)));
}

class MyApp extends StatelessWidget {
  final ApiService api;
  const MyApp({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cattle Breed AI',
      theme: ThemeData(colorSchemeSeed: Colors.brown, useMaterial3: true),
      home: PredictPage(api: api),
    );
  }
}
```

---

## 5) Emulator/device base URL tips

- Android emulator: `http://10.0.2.2:8000`
- iOS simulator: `http://127.0.0.1:8000`
- Physical device: `http://<YOUR_PC_LAN_IP>:8000`

Make sure PC and device are on the same network and firewall allows inbound on port 8000.

---

## 6) CORS

CORS is already enabled in `Deploy/app.py` via `CORSMiddleware(allow_origins=['*'])`. For production, restrict to your app’s domain(s).

---

## 7) Batch prediction (optional)

Use `/predict/batch` to upload multiple files:

```dart
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> predictBatch(String baseUrl, List<File> images) async {
  final uri = Uri.parse('$baseUrl/predict/batch');
  final req = http.MultipartRequest('POST', uri);
  for (final img in images) {
    req.files.add(await http.MultipartFile.fromPath('files', img.path));
  }
  final streamed = await req.send();
  final resp = await http.Response.fromStream(streamed);
  return jsonDecode(resp.body) as Map<String, dynamic>;
}
```

---

## 8) Troubleshooting

- 400 Invalid file type: Ensure you pass field name `file` and an image path.
- 503 Model not loaded: Verify `models/stable_cattle_model.pth` exists before starting the server.
- Device cannot reach server: Use LAN IP and ensure firewall allows port 8000.
- Large images: The API handles resizing; still, compress in the picker using `imageQuality`.

---

With this setup, your Flutter app can pick an image and get the cattle breed prediction from your FastAPI server. ✅
