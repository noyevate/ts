import 'package:flutter/material.dart';

class RText extends StatelessWidget {
  final String title;
  final TextStyle style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final TextDecoration? decoration;

  const RText({
    super.key,
    required this.title,
    required this.style,
    this.textAlign,
    this.overflow, this.decoration,
    
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: style.copyWith(
        fontFamily: style.fontFamily ?? 'Metropolis',
        decoration: decoration ?? TextDecoration.none  
      ) ,
      textAlign: textAlign ?? TextAlign.left,
      
      // overflow: overflow ?? TextOverflow.ellipsis,
      // softWrap: false,
    );
  }
}
