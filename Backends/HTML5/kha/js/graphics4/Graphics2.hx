package kha.js.graphics4;

import kha.Color;

class Graphics2 extends kha.graphics4.Graphics2 {
	public function new(canvas: Canvas) {
		super(canvas);
	}
	
	override public function drawVideo(video: kha.Video, x: Float, y: Float, width: Float, height: Float): Void {
		var v = cast(video, Video);
		drawScaledSubImage(v.texture, 0, 0, v.texture.width, v.texture.height, x, y, width, height);
	}
	
	override public function begin(clear: Bool = true, clearColor: Color = null): Void {
		Sys.gl.colorMask(true, true, true, true);
		super.begin(clear, clearColor);
	}
}
