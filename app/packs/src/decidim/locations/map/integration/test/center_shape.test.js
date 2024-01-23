import { centerShape } from "src/decidim/locations/map/integration/center_shape"

describe("centerShape function", () => {
  it("should calculate center for Line", () => {
    const coords = [{ lat: 10, lng: 20 }, { lat: 20, lng: 30 }, { lat: 30, lng: 40 }];
    const objectShape = "Line";
    const result = centerShape(coords, objectShape);

    expect(result).toEqual({ lat: 20, lng: 30 });
  });

  it("should calculate center for Polygon", () => {
    const coords = [[{ lat: 10, lng: 20 }, { lat: 20, lng: 30 }, { lat: 30, lng: 40 }]];
    const objectShape = "Polygon";
    const result = centerShape(coords, objectShape);

    expect(result).toEqual({ lat: 20, lng: 30 });
  });

  it("should return Marker coordinates as-is", () => {
    const coords = { lat: 10, lng: 20 };
    const objectShape = "Marker";
    const result = centerShape(coords, objectShape);

    expect(result).toEqual(coords);
  });
});
