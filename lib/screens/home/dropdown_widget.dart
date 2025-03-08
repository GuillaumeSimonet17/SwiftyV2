import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DropdownWidget extends StatefulWidget {
  final String username;
  final VoidCallback onLogout;

  const DropdownWidget({
    Key? key,
    required this.username,
    required this.onLogout,
  }) : super(key: key);

  @override
  _DropdownWidgetState createState() => _DropdownWidgetState();
}

class _DropdownWidgetState extends State<DropdownWidget> {
  late String? selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = 'logout';
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: Text(
          widget.username,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme
                .of(context)
                .colorScheme
                .primary,
          ),
        ),
        items: [
          DropdownMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Icon(
                  Icons.logout,
                  color: Theme
                      .of(context)
                      .colorScheme
                      .primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme
                        .of(context)
                        .colorScheme
                        .primary,
                  ),
                ),
              ],
            ),
          ),
        ],
        onChanged: (String? value) {
          setState(() {
            selectedValue = value;
            if (value == 'logout') {
              widget.onLogout();
            }
          });
        },
        buttonStyleData: ButtonStyleData(
          height: 50,
          width: 130,
          padding: const EdgeInsets.only(left: 14, right: 14),
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          elevation: 0,
        ),
        menuItemStyleData: const MenuItemStyleData(
          height: 40,
        ),
      ),
    );
  }
}