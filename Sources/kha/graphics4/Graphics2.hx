package kha.graphics4;

import kha.Canvas;
import kha.Font;
import kha.Image;
import kha.graphics4.BlendingOperation;
import kha.graphics4.ConstantLocation;
import kha.graphics4.IndexBuffer;
import kha.graphics4.MipMapFilter;
import kha.graphics4.Program;
import kha.graphics4.TextureAddressing;
import kha.graphics4.TextureFilter;
import kha.graphics4.TextureFormat;
import kha.graphics4.TextureUnit;
import kha.graphics4.Usage;
import kha.graphics4.VertexBuffer;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;
import kha.math.Matrix3;
import kha.math.Matrix4;
import kha.math.Vector2;

class ImageShaderPainter {
	private var projectionMatrix: Matrix4;
	private var shaderProgram: Program;
	private var structure: VertexStructure;
	private var projectionLocation: ConstantLocation;
	private var textureLocation: TextureUnit;
	private static var bufferSize: Int = 100;
	private static var vertexSize: Int = 9;
	private var bufferIndex: Int;
	private var rectVertexBuffer: VertexBuffer;
    private var rectVertices: Array<Float>;
	private var indexBuffer: IndexBuffer;
	private var lastTexture: Image;
	private var bilinear: Bool = false;
	private var g: Graphics;
	public var program: Program = null;
	
	public function new(g4: Graphics, projectionMatrix: Matrix4) {
		this.g = g4;
		this.projectionMatrix = projectionMatrix;
		bufferIndex = 0;
		initShaders();
		initBuffers();
		projectionLocation = shaderProgram.getConstantLocation("projectionMatrix");
		textureLocation = shaderProgram.getTextureUnit("tex");
	}
	
	public function setProjection(projectionMatrix: Matrix4): Void {
		this.projectionMatrix = projectionMatrix;
	}
	
	private function initShaders(): Void {
		var fragmentShader = new FragmentShader(Loader.the.getShader("painter-image.frag"));
		var vertexShader = new VertexShader(Loader.the.getShader("painter-image.vert"));
	
		shaderProgram = new Program();
		shaderProgram.setFragmentShader(fragmentShader);
		shaderProgram.setVertexShader(vertexShader);

		structure = new VertexStructure();
		structure.add("vertexPosition", VertexData.Float3);
		structure.add("texPosition", VertexData.Float2);
		structure.add("vertexColor", VertexData.Float4);
		
		shaderProgram.link(structure);
	}
	
	function initBuffers(): Void {
		rectVertexBuffer = new VertexBuffer(bufferSize * 4, structure, Usage.DynamicUsage);
		rectVertices = rectVertexBuffer.lock();
		
		indexBuffer = new IndexBuffer(bufferSize * 3 * 2, Usage.StaticUsage);
		var indices = indexBuffer.lock();
		for (i in 0...bufferSize) {
			indices[i * 3 * 2 + 0] = i * 4 + 0;
			indices[i * 3 * 2 + 1] = i * 4 + 1;
			indices[i * 3 * 2 + 2] = i * 4 + 2;
			indices[i * 3 * 2 + 3] = i * 4 + 0;
			indices[i * 3 * 2 + 4] = i * 4 + 2;
			indices[i * 3 * 2 + 5] = i * 4 + 3;
		}
		indexBuffer.unlock();
	}
	
	private function setRectVertices(left: Float, top: Float, right: Float, bottom: Float): Void {
		var baseIndex: Int = bufferIndex * vertexSize * 4;
		rectVertices[baseIndex +  0] = left;
		rectVertices[baseIndex +  1] = bottom;
		rectVertices[baseIndex +  2] = -5.0;
		
		rectVertices[baseIndex +  9] = left;
		rectVertices[baseIndex + 10] = top;
		rectVertices[baseIndex + 11] = -5.0;
		
		rectVertices[baseIndex + 18] = right;
		rectVertices[baseIndex + 19] = top;
		rectVertices[baseIndex + 20] = -5.0;
		
		rectVertices[baseIndex + 27] = right;
		rectVertices[baseIndex + 28] = bottom;
		rectVertices[baseIndex + 29] = -5.0;
	}
	
	private function setRectTexCoords(left: Float, top: Float, right: Float, bottom: Float): Void {
		var baseIndex: Int = bufferIndex * vertexSize * 4;
		rectVertices[baseIndex +  3] = left;
		rectVertices[baseIndex +  4] = bottom;
		
		rectVertices[baseIndex + 12] = left;
		rectVertices[baseIndex + 13] = top;
		
		rectVertices[baseIndex + 21] = right;
		rectVertices[baseIndex + 22] = top;
		
		rectVertices[baseIndex + 30] = right;
		rectVertices[baseIndex + 31] = bottom;
	}
	
	private function setRectColor(r: Float, g: Float, b: Float, a: Float): Void {
		var baseIndex: Int = bufferIndex * vertexSize * 4;
		rectVertices[baseIndex +  5] = r;
		rectVertices[baseIndex +  6] = g;
		rectVertices[baseIndex +  7] = b;
		rectVertices[baseIndex +  8] = a;
		
		rectVertices[baseIndex + 14] = r;
		rectVertices[baseIndex + 15] = g;
		rectVertices[baseIndex + 16] = b;
		rectVertices[baseIndex + 17] = a;
		
		rectVertices[baseIndex + 23] = r;
		rectVertices[baseIndex + 24] = g;
		rectVertices[baseIndex + 25] = b;
		rectVertices[baseIndex + 26] = a;
		
		rectVertices[baseIndex + 32] = r;
		rectVertices[baseIndex + 33] = g;
		rectVertices[baseIndex + 34] = b;
		rectVertices[baseIndex + 35] = a;
	}

	private function drawBuffer(): Void {
		g.setTexture(textureLocation, lastTexture);
		g.setTextureParameters(textureLocation, TextureAddressing.Clamp, TextureAddressing.Clamp, bilinear ? TextureFilter.LinearFilter : TextureFilter.PointFilter, bilinear ? TextureFilter.LinearFilter : TextureFilter.PointFilter, MipMapFilter.NoMipFilter);
		
		rectVertexBuffer.unlock();
		g.setVertexBuffer(rectVertexBuffer);
		g.setIndexBuffer(indexBuffer);
		g.setProgram(program == null ? shaderProgram : program);
		g.setMatrix(projectionLocation, projectionMatrix);
		
		g.setBlendingMode(BlendingOperation.BlendOne, BlendingOperation.InverseSourceAlpha);
		g.drawIndexedVertices(0, bufferIndex * 2 * 3);

		g.setTexture(textureLocation, null);
		bufferIndex = 0;
	}
	
	public function setBilinearFilter(bilinear: Bool): Void {
		end();
		this.bilinear = bilinear;
	}
	
	public function drawImage(img: kha.Image, left: Float, top: Float, right: Float, bottom: Float, opacity: Float, color: Color): Void {
		var tex = img;
		if (bufferIndex + 1 >= bufferSize || (lastTexture != null && tex != lastTexture)) drawBuffer();
		
		setRectColor(color.R, color.G, color.B, opacity);
		setRectTexCoords(0, 0, tex.width / tex.realWidth, tex.height / tex.realHeight);
		setRectVertices(left, top, right, bottom);
		
		++bufferIndex;
		lastTexture = tex;
	}
	
	public function drawImage2(img: kha.Image, sx: Float, sy: Float, sw: Float, sh: Float, left: Float, top: Float, right: Float, bottom: Float, opacity: Float, color: Color): Void {
		var tex = img;
		if (bufferIndex + 1 >= bufferSize || (lastTexture != null && tex != lastTexture)) drawBuffer();
		
		setRectTexCoords(sx / tex.realWidth, sy / tex.realHeight, (sx + sw) / tex.realWidth, (sy + sh) / tex.realHeight);
		setRectColor(color.R, color.G, color.B, opacity);
		setRectVertices(left, top, right, bottom);
		
		++bufferIndex;
		lastTexture = tex;
	}

	public function end(): Void {
		if (bufferIndex > 0) drawBuffer();
		lastTexture = null;
	}
}

class ColoredShaderPainter {
	private var projectionMatrix: Matrix4;
	private var shaderProgram: Program;
	private var structure: VertexStructure;
	private var projectionLocation: ConstantLocation;
	
	private static var bufferSize: Int = 100;
	private var bufferIndex: Int;
	private var rectVertexBuffer: VertexBuffer;
    private var rectVertices: Array<Float>;
	private var indexBuffer: IndexBuffer;
	
	private static var triangleBufferSize: Int = 100;
	private var triangleBufferIndex: Int;
	private var triangleVertexBuffer: VertexBuffer;
    private var triangleVertices: Array<Float>;
	private var triangleIndexBuffer: IndexBuffer;
	
	private var g: Graphics;
	public var program: Program = null;
	
	public function new(g4: Graphics, projectionMatrix: Matrix4) {
		this.g = g4;
		this.projectionMatrix = projectionMatrix;
		bufferIndex = 0;
		triangleBufferIndex = 0;
		initShaders();
		initBuffers();
		projectionLocation = shaderProgram.getConstantLocation("projectionMatrix");
	}

	public function setProjection(projectionMatrix: Matrix4): Void {
		this.projectionMatrix = projectionMatrix;
	}
	
	private function initShaders(): Void {
		var fragmentShader = new FragmentShader(Loader.the.getShader("painter-colored.frag"));
		var vertexShader = new VertexShader(Loader.the.getShader("painter-colored.vert"));
	
		shaderProgram = new Program();
		shaderProgram.setFragmentShader(fragmentShader);
		shaderProgram.setVertexShader(vertexShader);

		structure = new VertexStructure();
		structure.add("vertexPosition", VertexData.Float3);
		structure.add("vertexColor", VertexData.Float4);
		
		shaderProgram.link(structure);
	}
	
	function initBuffers(): Void {
		rectVertexBuffer = new VertexBuffer(bufferSize * 4, structure, Usage.DynamicUsage);
		rectVertices = rectVertexBuffer.lock();
		
		indexBuffer = new IndexBuffer(bufferSize * 3 * 2, Usage.StaticUsage);
		var indices = indexBuffer.lock();
		for (i in 0...bufferSize) {
			indices[i * 3 * 2 + 0] = i * 4 + 0;
			indices[i * 3 * 2 + 1] = i * 4 + 1;
			indices[i * 3 * 2 + 2] = i * 4 + 2;
			indices[i * 3 * 2 + 3] = i * 4 + 0;
			indices[i * 3 * 2 + 4] = i * 4 + 2;
			indices[i * 3 * 2 + 5] = i * 4 + 3;
		}
		indexBuffer.unlock();
		
		triangleVertexBuffer = new VertexBuffer(triangleBufferSize * 3, structure, Usage.DynamicUsage);
		triangleVertices = triangleVertexBuffer.lock();
		
		triangleIndexBuffer = new IndexBuffer(triangleBufferSize * 3, Usage.StaticUsage);
		var triIndices = triangleIndexBuffer.lock();
		for (i in 0...bufferSize) {
			triIndices[i * 3 + 0] = i * 3 + 0;
			triIndices[i * 3 + 1] = i * 3 + 1;
			triIndices[i * 3 + 2] = i * 3 + 2;
		}
		triangleIndexBuffer.unlock();
	}
	
	public function setRectVertices(left: Float, top: Float, right: Float, bottom: Float): Void {
		var baseIndex: Int = bufferIndex * 7 * 4;
		rectVertices[baseIndex +  0] = left;
		rectVertices[baseIndex +  1] = bottom;
		rectVertices[baseIndex +  2] = -5.0;
		
		rectVertices[baseIndex +  7] = left;
		rectVertices[baseIndex +  8] = top;
		rectVertices[baseIndex +  9] = -5.0;
		
		rectVertices[baseIndex + 14] = right;
		rectVertices[baseIndex + 15] = top;
		rectVertices[baseIndex + 16] = -5.0;
		
		rectVertices[baseIndex + 21] = right;
		rectVertices[baseIndex + 22] = bottom;
		rectVertices[baseIndex + 23] = -5.0;
	}
	
	public function setRectColors(color: Color): Void {
		var baseIndex: Int = bufferIndex * 7 * 4;
		rectVertices[baseIndex +  3] = color.R;
		rectVertices[baseIndex +  4] = color.G;
		rectVertices[baseIndex +  5] = color.B;
		rectVertices[baseIndex +  6] = color.A;
		
		rectVertices[baseIndex + 10] = color.R;
		rectVertices[baseIndex + 11] = color.G;
		rectVertices[baseIndex + 12] = color.B;
		rectVertices[baseIndex + 13] = color.A;
		
		rectVertices[baseIndex + 17] = color.R;
		rectVertices[baseIndex + 18] = color.G;
		rectVertices[baseIndex + 19] = color.B;
		rectVertices[baseIndex + 20] = color.A;
		
		rectVertices[baseIndex + 24] = color.R;
		rectVertices[baseIndex + 25] = color.G;
		rectVertices[baseIndex + 26] = color.B;
		rectVertices[baseIndex + 27] = color.A;
	}
	
	private function setTriVertices(x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float): Void {
		var baseIndex: Int = triangleBufferIndex * 7 * 3;
		triangleVertices[baseIndex +  0] = x1;
		triangleVertices[baseIndex +  1] = y1;
		triangleVertices[baseIndex +  2] = -5.0;
		
		triangleVertices[baseIndex +  7] = x2;
		triangleVertices[baseIndex +  8] = y2;
		triangleVertices[baseIndex +  9] = -5.0;
		
		triangleVertices[baseIndex + 14] = x3;
		triangleVertices[baseIndex + 15] = y3;
		triangleVertices[baseIndex + 16] = -5.0;
	}
	
	private function setTriColors(color: Color): Void {
		var baseIndex: Int = triangleBufferIndex * 7 * 3;
		triangleVertices[baseIndex +  3] = color.R;
		triangleVertices[baseIndex +  4] = color.G;
		triangleVertices[baseIndex +  5] = color.B;
		triangleVertices[baseIndex +  6] = color.A;
		
		triangleVertices[baseIndex + 10] = color.R;
		triangleVertices[baseIndex + 11] = color.G;
		triangleVertices[baseIndex + 12] = color.B;
		triangleVertices[baseIndex + 13] = color.A;
		
		triangleVertices[baseIndex + 17] = color.R;
		triangleVertices[baseIndex + 18] = color.G;
		triangleVertices[baseIndex + 19] = color.B;
		triangleVertices[baseIndex + 20] = color.A;
	}

	private function drawBuffer(trisDone: Bool): Void {
		if (!trisDone) endTris(true);
		
		rectVertexBuffer.unlock();
		g.setVertexBuffer(rectVertexBuffer);
		g.setIndexBuffer(indexBuffer);
		g.setProgram(program == null ? shaderProgram : program);
		g.setMatrix(projectionLocation, projectionMatrix);
		
		g.setBlendingMode(BlendingOperation.SourceAlpha, BlendingOperation.InverseSourceAlpha);
		g.drawIndexedVertices(0, bufferIndex * 2 * 3);

		bufferIndex = 0;
	}
	
	private function drawTriBuffer(rectsDone: Bool): Void {
		if (!rectsDone) endRects(true);
		
		triangleVertexBuffer.unlock();
		g.setVertexBuffer(triangleVertexBuffer);
		g.setIndexBuffer(triangleIndexBuffer);
		g.setProgram(shaderProgram);
		g.setMatrix(projectionLocation, projectionMatrix);
		
		g.drawIndexedVertices(0, triangleBufferIndex * 3);

		triangleBufferIndex = 0;
	}
	
	public function fillRect(color: Color, left: Float, top: Float, right: Float, bottom: Float): Void {
		if (bufferIndex + 1 >= bufferSize) drawBuffer(false);
				
		setRectColors(color);
		setRectVertices(left, top, right, bottom);
		++bufferIndex;
	}
	
	public function fillTriangle(color: Color, x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float) {
		if (triangleBufferIndex + 1 >= triangleBufferSize) drawTriBuffer(false);
		
		setTriColors(color);
		setTriVertices(x1, y1, x2, y2, x3, y3);
		++triangleBufferIndex;
	}
	
	public function endTris(rectsDone: Bool): Void {
		if (triangleBufferIndex > 0) drawTriBuffer(rectsDone);
	}
	
	public function endRects(trisDone: Bool): Void {
		if (bufferIndex > 0) drawBuffer(trisDone);
	}
	
	public function end(): Void {
		endTris(false);
		endRects(false);
	}
}

@:headerClassCode("const wchar_t* wtext;")
class TextShaderPainter {
	private var projectionMatrix: Matrix4;
	private var shaderProgram: Program;
	private var structure: VertexStructure;
	private var projectionLocation: ConstantLocation;
	private var textureLocation: TextureUnit;
	private static var bufferSize: Int = 100;
	private var bufferIndex: Int;
	private var rectVertexBuffer: VertexBuffer;
    private var rectVertices: Array<Float>;
	private var indexBuffer: IndexBuffer;
	private var font: Kravur;
	private var lastTexture: Image;
	private var g: Graphics;
	public var program: Program = null;
	
	public function new(g4: Graphics, projectionMatrix: Matrix4) {
		this.g = g4;
		this.projectionMatrix = projectionMatrix;
		bufferIndex = 0;
		initShaders();
		initBuffers();
		projectionLocation = shaderProgram.getConstantLocation("projectionMatrix");
		textureLocation = shaderProgram.getTextureUnit("tex");
	}
	
	private function initShaders(): Void {
		var fragmentShader = new FragmentShader(Loader.the.getShader("painter-text.frag"));
		var vertexShader = new VertexShader(Loader.the.getShader("painter-text.vert"));
	
		shaderProgram = new Program();
		shaderProgram.setFragmentShader(fragmentShader);
		shaderProgram.setVertexShader(vertexShader);

		structure = new VertexStructure();
		structure.add("vertexPosition", VertexData.Float3);
		structure.add("texPosition", VertexData.Float2);
		structure.add("vertexColor", VertexData.Float4);
		
		shaderProgram.link(structure);
	}
	
	function initBuffers(): Void {
		rectVertexBuffer = new VertexBuffer(bufferSize * 4, structure, Usage.DynamicUsage);
		rectVertices = rectVertexBuffer.lock();
		
		indexBuffer = new IndexBuffer(bufferSize * 3 * 2, Usage.StaticUsage);
		var indices = indexBuffer.lock();
		for (i in 0...bufferSize) {
			indices[i * 3 * 2 + 0] = i * 4 + 0;
			indices[i * 3 * 2 + 1] = i * 4 + 1;
			indices[i * 3 * 2 + 2] = i * 4 + 2;
			indices[i * 3 * 2 + 3] = i * 4 + 0;
			indices[i * 3 * 2 + 4] = i * 4 + 2;
			indices[i * 3 * 2 + 5] = i * 4 + 3;
		}
		indexBuffer.unlock();
	}
	
	private function setRectVertices(left: Float, top: Float, right: Float, bottom: Float): Void {
		var baseIndex: Int = bufferIndex * 9 * 4;
		rectVertices[baseIndex +  0] = left;
		rectVertices[baseIndex +  1] = bottom;
		rectVertices[baseIndex +  2] = -5.0;
		
		rectVertices[baseIndex +  9] = left;
		rectVertices[baseIndex + 10] = top;
		rectVertices[baseIndex + 11] = -5.0;
		
		rectVertices[baseIndex + 18] = right;
		rectVertices[baseIndex + 19] = top;
		rectVertices[baseIndex + 20] = -5.0;
		
		rectVertices[baseIndex + 27] = right;
		rectVertices[baseIndex + 28] = bottom;
		rectVertices[baseIndex + 29] = -5.0;
	}
	
	private function setRectTexCoords(left: Float, top: Float, right: Float, bottom: Float): Void {
		var baseIndex: Int = bufferIndex * 9 * 4;
		rectVertices[baseIndex +  3] = left;
		rectVertices[baseIndex +  4] = bottom;
		
		rectVertices[baseIndex + 12] = left;
		rectVertices[baseIndex + 13] = top;
		
		rectVertices[baseIndex + 21] = right;
		rectVertices[baseIndex + 22] = top;
		
		rectVertices[baseIndex + 30] = right;
		rectVertices[baseIndex + 31] = bottom;
	}
	
	private function setRectColors(color: Color): Void {
		var baseIndex: Int = bufferIndex * 9 * 4;
		rectVertices[baseIndex +  5] = color.R;
		rectVertices[baseIndex +  6] = color.G;
		rectVertices[baseIndex +  7] = color.B;
		rectVertices[baseIndex +  8] = color.A;
		
		rectVertices[baseIndex + 14] = color.R;
		rectVertices[baseIndex + 15] = color.G;
		rectVertices[baseIndex + 16] = color.B;
		rectVertices[baseIndex + 17] = color.A;
		
		rectVertices[baseIndex + 23] = color.R;
		rectVertices[baseIndex + 24] = color.G;
		rectVertices[baseIndex + 25] = color.B;
		rectVertices[baseIndex + 26] = color.A;
		
		rectVertices[baseIndex + 32] = color.R;
		rectVertices[baseIndex + 33] = color.G;
		rectVertices[baseIndex + 34] = color.B;
		rectVertices[baseIndex + 35] = color.A;
	}
	
	private function drawBuffer(): Void {
		g.setTexture(textureLocation, lastTexture);
		
		rectVertexBuffer.unlock();
		g.setVertexBuffer(rectVertexBuffer);
		g.setIndexBuffer(indexBuffer);
		g.setProgram(program == null ? shaderProgram : program);
		g.setMatrix(projectionLocation, projectionMatrix);
		
		g.setBlendingMode(BlendingOperation.SourceAlpha, BlendingOperation.InverseSourceAlpha);
		g.drawIndexedVertices(0, bufferIndex * 2 * 3);

		g.setTexture(textureLocation, null);
		bufferIndex = 0;
	}
	
	public function setFont(font: Font): Void {
		this.font = cast(font, Kravur);
	}
	
	private var text: String;
	
	@:functionCode('
		wtext = text.__WCStr();
	')
	private function startString(text: String): Void {
		this.text = text;
	}
	
	@:functionCode('
		return wtext[position];
	')
	private function charCodeAt(position: Int): Int {
		return text.charCodeAt(position);
	}
	
	@:functionCode('
		return wcslen(wtext);
	')
	private function stringLength(): Int {
		return text.length;
	}
	
	@:functionCode('
		wtext = 0;
	')
	private function endString(): Void {
		text = null;
	}
	
	public function drawString(text: String, color: Color, x: Float, y: Float, transformation: Matrix3): Void {
		var tex = font.getTexture();
		if (lastTexture != null && tex != lastTexture) drawBuffer();
		lastTexture = tex;

		var xpos = x;
		var ypos = y;
		startString(text);
		for (i in 0...stringLength()) {
			var q = font.getBakedQuad(charCodeAt(i) - 32, xpos, ypos);
			if (q != null) {
				if (bufferIndex + 1 >= bufferSize) drawBuffer();
				setRectColors(color);
				setRectTexCoords(q.s0 * tex.width / tex.realWidth, q.t0 * tex.height / tex.realHeight, q.s1 * tex.width / tex.realWidth, q.t1 * tex.height / tex.realHeight);
				var p0 = transformation.multvec(new Vector2(q.x0, q.y0));
				var p1 = transformation.multvec(new Vector2(q.x1, q.y1));
				setRectVertices(p0.x, p0.y, p1.x, p1.y);
				xpos += q.xadvance;
				++bufferIndex;
			}
		}
		endString();
	}
	
	public function end(): Void {
		if (bufferIndex > 0) drawBuffer();
		lastTexture = null;
	}
}

class Graphics2 extends kha.graphics2.Graphics {
	private var myColor: Color;
	private var myFont: Font;
	private var projectionMatrix: Matrix4;
	private var imagePainter: ImageShaderPainter;
	private var coloredPainter: ColoredShaderPainter;
	private var textPainter: TextShaderPainter;
	private var width: Float;
	private var height: Float;
	private var renderTexture: Image;
	
	private var g: Graphics;
	
	public function new(g4: Graphics, width: Int, height: Int) {
		super();
		color = Color.White;
		renderTexture = null;
		g = g4;
		setScreenSize(width, height);
	}
	
	private function setScreenSize(width: Int, height: Int) {
		if (renderTexture == null || renderTexture.width != width || renderTexture.height != height) {
			renderTexture = Image.createRenderTarget(width, height);
		}
		this.width = renderTexture.realWidth;
		this.height = renderTexture.realHeight;
		//projectionMatrix = ortho( 0, width, height, 0, 0.1, 1000);
		projectionMatrix = Matrix4.orthogonalProjection(0, renderTexture.realWidth, renderTexture.realHeight, 0, 0.1, 1000);
		imagePainter = new ImageShaderPainter(g, projectionMatrix);
		coloredPainter = new ColoredShaderPainter(g, projectionMatrix);
		textPainter = new TextShaderPainter(g, projectionMatrix);
	}
	
	public override function drawImage(img: kha.Image, x: Float, y: Float): Void {
		coloredPainter.end();
		textPainter.end();
		var p1 = transformation.multvec(new Vector2(x, y));
		var p2 = transformation.multvec(new Vector2(x + img.width, y + img.height));
		imagePainter.drawImage(img, p1.x, p1.y, p2.x, p2.y, opacity, this.color);
	}
	
	public override function drawScaledSubImage(img: kha.Image, sx: Float, sy: Float, sw: Float, sh: Float, dx: Float, dy: Float, dw: Float, dh: Float): Void {
		coloredPainter.end();
		textPainter.end();
		var p1 = transformation.multvec(new Vector2(dx, dy));
		var p2 = transformation.multvec(new Vector2(dx + dw, dy + dh));
		imagePainter.drawImage2(img, sx, sy, sw, sh, p1.x, p1.y, p2.x, p2.y, opacity, this.color);
	}
	
	override public function get_color(): Color {
		return myColor;
	}
	
	override public function set_color(color: Color): Color {
		return myColor = color;
	}
	
	public override function drawRect(x: Float, y: Float, width: Float, height: Float, strength: Float = 1.0): Void {
		imagePainter.end();
		textPainter.end();
		
		var p1 = transformation.multvec(new Vector2(x, y));
		var p2 = transformation.multvec(new Vector2(x + width, y + strength));
		coloredPainter.fillRect(color, p1.x, p1.y, p2.x, p2.y);
		p2 = transformation.multvec(new Vector2(x + strength, y + height));
		coloredPainter.fillRect(color, p1.x, p1.y, p2.x, p2.y);
		p1 = transformation.multvec(new Vector2(x, y + height));
		p2 = transformation.multvec(new Vector2(x + width, y - strength));
		coloredPainter.fillRect(color, p1.x, p1.y, p2.x, p2.y);
		p1 = transformation.multvec(new Vector2(x + width, y));
		p2 = transformation.multvec(new Vector2(x - strength, y + height));
		coloredPainter.fillRect(color, p1.x, p1.y, p2.x, p2.y);
	}
	
	public override function fillRect(x: Float, y: Float, width: Float, height: Float): Void {
		imagePainter.end();
		textPainter.end();
		
		var p1 = transformation.multvec(new Vector2(x, y));
		var p2 = transformation.multvec(new Vector2(x + width, y + height));
		coloredPainter.fillRect(color, p1.x, p1.y, p2.x, p2.y);
	}

	public override function drawString(text: String, x: Float, y: Float): Void {
		imagePainter.end();
		coloredPainter.end();
		
		textPainter.drawString(text, color, x, y, transformation);
	}

	override public function get_font(): Font {
		return myFont;
	}
	
	override public function set_font(font: Font): Font {
		textPainter.setFont(font);
		return myFont = font;
	}

	public override function drawLine(x1: Float, y1: Float, x2: Float, y2: Float, strength: Float = 1.0): Void {
		imagePainter.end();
		textPainter.end();
		
		var vec: Vector2;
		if (y2 == y1) vec = new Vector2(0, -1);
		else vec = new Vector2(1, -(x2 - x1) / (y2 - y1));
		vec.length = strength;
		var p1 = new Vector2(x1 + 0.5 * vec.x, y1 + 0.5 * vec.y);
		var p2 = new Vector2(x2 + 0.5 * vec.x, y2 + 0.5 * vec.y);
		var p3 = p1.sub(vec);
		var p4 = p2.sub(vec);
		
		p1 = transformation.multvec(p1);
		p2 = transformation.multvec(p2);
		p3 = transformation.multvec(p3);
		p4 = transformation.multvec(p4);
		
		coloredPainter.fillTriangle(color, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
		coloredPainter.fillTriangle(color, p3.x, p3.y, p2.x, p2.y, p4.x, p4.y);		
	}

	public override function fillTriangle(x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float) {
		imagePainter.end();
		textPainter.end();
		
		var p1 = transformation.multvec(new Vector2(x1, y1));
		var p2 = transformation.multvec(new Vector2(x2, y2));
		var p3 = transformation.multvec(new Vector2(x3, y3));
		coloredPainter.fillTriangle(color, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
	}
	
	public function setBilinearFiltering(bilinear: Bool): Void {
		imagePainter.setBilinearFilter(bilinear);
	}
	
	override private function setProgram(program: Program): Void {
		end();
		imagePainter.program = program;
		coloredPainter.program = program;
		textPainter.program = program;
	}
	
	override public function setBlendingMode(source: BlendingOperation, destination: BlendingOperation): Void {
		end();
		g.setBlendingMode(source, destination);
	}
	
	public override function begin(): Void {
		g.clear(kha.Color.fromBytes(0, 0, 0, 0));
		//translate(0, 0);
	}
	
	public override function end(): Void {
		imagePainter.end();
		textPainter.end();
		coloredPainter.end();
	}
}