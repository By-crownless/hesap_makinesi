import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:math_expressions/math_expressions.dart';

void main() => runApp(const HesapMakinesiApp());

class HesapMakinesiApp extends StatelessWidget {
  const HesapMakinesiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HesapMakinesi(),
    );
  }
}

class HesapMakinesi extends StatefulWidget {
  const HesapMakinesi({super.key});
  @override
  State<HesapMakinesi> createState() => _HesapMakinesiState();
}

class _HesapMakinesiState extends State<HesapMakinesi> {
  final TextEditingController _controller = TextEditingController();
  String _canliSonuc = "";
  bool _hesaplandiMi = false;
  List<Map<String, String>> _gecmis = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _kopyala(String metin) {
    if (metin.isEmpty || metin == "0") return;
    Clipboard.setData(ClipboardData(text: metin));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Kopyalandı!"),
        backgroundColor: Colors.amber,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _anlikHesapla(String metin) {
    if (metin.isEmpty) {
      setState(() => _canliSonuc = "");
      return;
    }
    String sonKarakter = metin.substring(metin.length - 1);
    if (["+", "-", "x", "/"].contains(sonKarakter)) return;

    try {
      String formuller = metin.replaceAll('x', '*');
      Parser p = Parser();
      Expression exp = p.parse(formuller);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);
      
      setState(() {
        _canliSonuc = eval.toString().endsWith(".0") 
            ? eval.toInt().toString() 
            : eval.toString();
      });
    } catch (e) {}
  }

  void _tusBasildi(String metin) {
    int start = _controller.selection.start;
    int end = _controller.selection.end;
    String mevcutMetin = _controller.text;

    setState(() {
      List<String> operatorler = ["+", "-", "x", "/"];

      if (metin == "C") {
        _controller.clear();
        _canliSonuc = "";
        _hesaplandiMi = false;
      } 
      else if (metin == "⌫") {
        if (start > 0 || start != end) {
          if (start == end) {
            final textBefore = mevcutMetin.substring(0, start - 1);
            final textAfter = mevcutMetin.substring(start);
            _controller.text = textBefore + textAfter;
            _controller.selection = TextSelection.collapsed(offset: start - 1);
          } else {
            final textBefore = mevcutMetin.substring(0, start);
            final textAfter = mevcutMetin.substring(end);
            _controller.text = textBefore + textAfter;
            _controller.selection = TextSelection.collapsed(offset: start);
          }
          _anlikHesapla(_controller.text);
        }
        _hesaplandiMi = false;
      } 
      else if (metin == "=") {
        if (_canliSonuc.isNotEmpty) {
          _gecmis.insert(0, {"islem": _controller.text, "sonuc": _canliSonuc});
          if (_gecmis.length > 20) _gecmis.removeLast();
          _controller.text = _canliSonuc;
          _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
          _canliSonuc = "";
          _hesaplandiMi = true;
        }
      } 
      else if (operatorler.contains(metin)) {
        if (mevcutMetin.isEmpty) return;
        if (start > 0 && operatorler.contains(mevcutMetin[start - 1])) {
           final textBefore = mevcutMetin.substring(0, start - 1);
           final textAfter = mevcutMetin.substring(start);
           _controller.text = textBefore + metin + textAfter;
           _controller.selection = TextSelection.collapsed(offset: start);
        } else {
           final textBefore = mevcutMetin.substring(0, start);
           final textAfter = mevcutMetin.substring(end);
           _controller.text = textBefore + metin + textAfter;
           _controller.selection = TextSelection.collapsed(offset: start + 1);
        }
        _hesaplandiMi = false;
      } 
      else {
        if (_hesaplandiMi) {
          _controller.text = metin;
          _hesaplandiMi = false;
        } else {
          final textBefore = mevcutMetin.substring(0, start);
          final textAfter = mevcutMetin.substring(end);
          _controller.text = textBefore + metin + textAfter;
        }
        _controller.selection = TextSelection.collapsed(offset: start + metin.length);
        _anlikHesapla(_controller.text);
      }
    });
  }

  void _gecmisGoster() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              const Text("Son 20 İşlem", style: TextStyle(fontSize: 18, color: Colors.grey)),
              const Expanded(child: SizedBox()), // Basit tutuldu
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.history, color: Colors.amber),
          onPressed: _gecmisGoster,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onLongPress: () => _kopyala(_controller.text),
                      child: TextField(
                        controller: _controller,
                        readOnly: true,
                        showCursor: true,
                        cursorColor: Colors.white, // BEYAZ İMLEÇ
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: _hesaplandiMi ? 50 : 35,
                          color: _hesaplandiMi ? Colors.amber : Colors.white,
                        ),
                        decoration: const InputDecoration(border: InputBorder.none),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (!_hesaplandiMi)
                      GestureDetector(
                        onLongPress: () => _kopyala(_canliSonuc),
                        child: Text(_canliSonuc, style: TextStyle(fontSize: 28, color: Colors.amber.withOpacity(0.5))),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 7,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                _btn("C", isAmber: true),
                                _btn("⌫", isAmber: true),
                                _btn("/", isGreen: true),
                              ],
                            ),
                          ),
                          Expanded(child: Row(children: [_btn("7"), _btn("8"), _btn("9")])),
                          Expanded(child: Row(children: [_btn("4"), _btn("5"), _btn("6")])),
                          Expanded(child: Row(children: [_btn("1"), _btn("2"), _btn("3")])),
                          Expanded(child: Row(children: [_btn("0", flex: 2), _btn(".")])),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _btn("x", isGreen: true),
                          _btn("-", isGreen: true),
                          _btn("+", isGreen: true),
                          _btn("=", isBlue: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(String metin, {int flex = 1, bool isAmber = false, bool isGreen = false, bool isBlue = false}) {
    Color btnColor = Colors.grey[900]!;
    Color textColor = Colors.white;

    if (isAmber) {
      btnColor = Colors.amber;
      textColor = Colors.black;
    } else if (isBlue) {
      btnColor = Colors.blueAccent;
    } else if (isGreen) {
      btnColor = const Color(0xFF1B5E20).withOpacity(0.3);
      textColor = Colors.greenAccent;
    }

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: InkWell(
          onTap: () => _tusBasildi(metin),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            decoration: BoxDecoration(color: btnColor, borderRadius: BorderRadius.circular(15)),
            child: Center(
              child: Text(
                metin, 
                style: TextStyle( // CONST SİLİNDİ
                  fontSize: 22, 
                  fontWeight: FontWeight.bold, 
                  color: textColor
                )
              )
            ),
          ),
        ),
      ),
    );
  }
}