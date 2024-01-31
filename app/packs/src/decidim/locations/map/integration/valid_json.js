const validJson = function (value) {
  try {
    JSON.parse(value);
    return true;
  } catch (error) {
    return false;
  }
};

export default validJson;
