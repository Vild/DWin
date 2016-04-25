module dwin.data.changed;

struct Changed(T) {
public:
	T data;
	alias data this;
	
	T opAssign(T newData) {
		oldData = data;
		data = newData;
		return data;
	}

	T clear() {
		oldData = data;
		return data;
	}
	
	@property bool changed() {
		return oldData != data;
	}
	
private:
	T oldData;
}
