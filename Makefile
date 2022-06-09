CC = clang
STD = -std=gnu99
OBJC = -lobjc
ARGS = $(arguments)
CFLAGS  = -g -Wall
RUNTIME = -fobjc-arc -fobjc-runtime=macosx-12 -Wno-deprecated-declarations
FRAMEWORK = -framework Foundation -framework AVFoundation -framework CoreMedia -framework CoreVideo -framework Photos

OBJCFILES = $(MFILES)
TARGET = main

MFILES = $(wildcard Basic ./*.m)

all: build run
build:
	$(CC) $(STD) $(OBJC) $(FRAMEWORK) $(OBJCFILES) $(RUNTIME) -o $(TARGET)
run:
	./$(TARGET) $(ARGS)
clean:
	rm $(TARGET)
