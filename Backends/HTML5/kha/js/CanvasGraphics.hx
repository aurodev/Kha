package kha.js;

import js.Browser;
import kha.Color;
import kha.FontStyle;
import kha.graphics2.Graphics;
import kha.Kravur;
import kha.math.Matrix3;
import kha.Rotation;

class CanvasGraphics extends Graphics {
	var canvas: Dynamic;
	var webfont: kha.js.Font;
	var width: Int;
	var height: Int;
	private var myColor: Color;
	private static var instance: CanvasGraphics;
	
	public function new(canvas: Dynamic, width: Int, height: Int) {
		super();
		this.canvas = canvas;
		this.width = width;
		this.height = height;
		instance = this;
		myColor = Color.fromBytes(0, 0, 0);
		//webfont = new Font("Arial", new FontStyle(false, false, false), 12);
		//canvas.globalCompositeOperation = "normal";
	}
	
	public static function stringWidth(font: kha.Font, text: String): Float {
		if (instance == null) return 5 * text.length;
		else {
			instance.font = font;
			return instance.canvas.measureText(text).width;
		}
	}
	
	override public function begin(clear: Bool = true, clearColor: Color = null): Void {
		if (clear) this.clear(clearColor);
	}
	
	override public function clear(color: Color = null): Void {
		if (color == null) color = Color.Black;
		canvas.strokeStyle = "rgb(" + color.Rb + "," + color.Gb + "," + color.Bb + ")";
		canvas.fillStyle = "rgb(" + color.Rb + "," + color.Gb + "," + color.Bb + ")";
		canvas.fillRect(0, 0, width, height);
		this.color = myColor;
	}
	
	override public function end(): Void {
		
	}
	
	/*override public function translate(x: Float, y: Float) {
		tx = x;
		ty = y;
	}*/
	
	override public function drawImage(img: kha.Image, x: Float, y: Float) {
		canvas.globalAlpha = opacity;
		canvas.drawImage(cast(img, CanvasImage).image, x, y);
		canvas.globalAlpha = 1;
	}
	
	override public function drawScaledSubImage(image: kha.Image, sx: Float, sy: Float, sw: Float, sh: Float, dx: Float, dy: Float, dw: Float, dh: Float) {
		canvas.globalAlpha = opacity;
		try {
			if (dw < 0 || dh < 0) {
				canvas.save();
				canvas.translate(dx, dy);
				var x = 0.0;
				var y = 0.0;
				if (dw < 0) {
					canvas.scale(-1, 1);
					x = -dw;
				}
				if (dh < 0) {
					canvas.scale(1, -1);
					y = -dh;
				}
				canvas.drawImage(cast(image, CanvasImage).image, sx, sy, sw, sh, x, y, dw, dh);
				canvas.restore();
			}
			else {
				canvas.drawImage(cast(image, CanvasImage).image, sx, sy, sw, sh, dx, dy, dw, dh);
			}
		}
		catch (ex: Dynamic) {
			
		}
		canvas.globalAlpha = 1;
	}
	
	override public function set_color(color: Color): Color {
		myColor = color;
		canvas.strokeStyle = "rgb(" + color.Rb + "," + color.Gb + "," + color.Bb + ")";
		canvas.fillStyle = "rgb(" + color.Rb + "," + color.Gb + "," + color.Bb + ")";
		return color;
	}
	
	override public function get_color(): Color {
		return myColor;
	}
	
	override public function drawRect(x: Float, y: Float, width: Float, height: Float, strength: Float = 1.0) {
		canvas.beginPath();
		var oldStrength = canvas.lineWidth;
		canvas.lineWidth = Math.round(strength);
		canvas.rect(x, y, width, height);
		canvas.stroke();
		canvas.lineWidth = oldStrength;
	}
	
	override public function fillRect(x: Float, y: Float, width: Float, height: Float) {
		canvas.globalAlpha = opacity * myColor.A;
		canvas.fillRect(x, y, width, height);
		canvas.globalAlpha = opacity;
	}
	
	override public function drawString(text: String, x: Float, y: Float) {
		//canvas.fillText(text, tx + x, ty + y + webfont.getHeight());
		//canvas.drawImage(cast(webfont.getTexture(), Image).image, 0, 0, 50, 50, tx + x, ty + y, 50, 50);
		
		var image = webfont.getImage(myColor);
		if (image.width > 0) {
			// the image created in getImage() is not imediately useable
			var xpos = x;
			var ypos = y;
			for (i in 0...text.length) {
				var q = webfont.kravur.getBakedQuad(text.charCodeAt(i) - 32, xpos, ypos);
				if (q != null) {
					if (q.s1 - q.s0 > 0 && q.t1 - q.t0 > 0 && q.x1 - q.x0 > 0 && q.y1 - q.y0 > 0)
						canvas.drawImage(image, q.s0 * image.width, q.t0 * image.height, (q.s1 - q.s0) * image.width, (q.t1 - q.t0) * image.height, q.x0, q.y0, q.x1 - q.x0, q.y1 - q.y0);
					xpos += q.xadvance;
				}
			}
		}
	}

	override public function set_font(font: kha.Font): kha.Font {
		webfont = cast(font, kha.js.Font);
		//canvas.font = webfont.size + "px " + webfont.name;
		return webfont;
	}
	
	override public function get_font(): kha.Font {
		return webfont;
	}

	override public function drawLine(x1: Float, y1: Float, x2: Float, y2: Float, strength: Float = 1.0) {
		canvas.beginPath();
		var oldWith = canvas.lineWidth;
		canvas.lineWidth = Math.round(strength);
		canvas.moveTo(x1, y1);
		canvas.lineTo(x2, y2);
		canvas.moveTo(0, 0);
		canvas.stroke();
		canvas.lineWidth = oldWith;
	}

	override public function fillTriangle(x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float) {
		canvas.beginPath();
		
		canvas.closePath();
		canvas.fill();
	}
	
	override public function drawVideo(video: kha.Video, x: Float, y: Float, width: Float, height: Float): Void {
		canvas.drawImage(cast(video, Video).element, x, y, width, height);
	}
	
	override public function setTransformation(transformation: Matrix3): Void {
		canvas.setTransform(transformation[0], transformation[3], transformation[1],
			transformation[4], transformation[2], transformation[5]);
	}
}
