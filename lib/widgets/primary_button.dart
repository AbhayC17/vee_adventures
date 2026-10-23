import 'package:flutter/material.dart';
import '../app/design_tokens.dart';

class WorldButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color color;
  const WorldButton({super.key, required this.child, required this.onPressed, this.color=VeeTokens.yellow});
  @override State<WorldButton> createState()=>_WorldButtonState();
}
class _WorldButtonState extends State<WorldButton> {
  bool down=false;
  @override Widget build(BuildContext context)=>GestureDetector(
    onTapDown: widget.onPressed==null ? null : (_)=>setState(()=>down=true),
    onTapCancel: ()=>setState(()=>down=false),
    onTapUp: widget.onPressed==null ? null : (_){setState(()=>down=false); widget.onPressed!();},
    child: AnimatedScale(scale:down ? .97 : 1.0, duration:const Duration(milliseconds:80), child: Container(
      padding: const EdgeInsets.symmetric(horizontal:22,vertical:16),
      decoration: BoxDecoration(color: widget.onPressed==null ? VeeTokens.creamDeep : widget.color, borderRadius:BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color:VeeTokens.shadow,blurRadius:12,offset:Offset(0,6))]),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 150),
        child: Center(
          child: DefaultTextStyle.merge(
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: VeeTokens.readableForeground(
                widget.onPressed == null ? VeeTokens.creamDeep : widget.color,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    )));
}
