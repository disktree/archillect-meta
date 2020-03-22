
import cv2
import struct
import sys

file = sys.argv[1]
face_cascade = cv2.CascadeClassifier('bin/haarcascade_frontalface_default.xml')
img = cv2.imread(file)
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
faces = face_cascade.detectMultiScale(gray, 1.1, 4)
for (x, y, w, h) in faces:
	sys.stdout.buffer.write(bytearray(struct.pack("i", x)))
	sys.stdout.buffer.write(bytearray(struct.pack("i", y)))
	sys.stdout.buffer.write(bytearray(struct.pack("i", w)))
	sys.stdout.buffer.write(bytearray(struct.pack("i", h)))
	#print(x,y,w,h)
#    cv2.rectangle(img, (x, y), (x+w, y+h), (255, 0, 0), 2)
# Display the output
#cv2.imshow('img', img)
#cv2.waitKey()
