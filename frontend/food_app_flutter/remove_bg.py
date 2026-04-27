from PIL import Image

def remove_white_bg(image_path, output_path, threshold=200):
    img = Image.open(image_path).convert("RGBA")
    data = img.getdata()
    
    new_data = []
    for item in data:
        # If the pixel is close to white, make it transparent
        if item[0] > threshold and item[1] > threshold and item[2] > threshold:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)
            
    img.putdata(new_data)
    img.save(output_path, "PNG")

remove_white_bg(r"C:\Users\fuzzu Developer\.gemini\antigravity\brain\682ce6da-13bb-45cf-b46f-101e3c3646a6\media__1775312756133.jpg", r"assets\app_icon.png")
