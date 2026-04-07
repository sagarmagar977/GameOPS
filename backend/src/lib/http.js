export function ok(res, data, status = 200) {
  return res.status(status).json({ data });
}

export function fail(res, message, status = 400, details = undefined) {
  return res.status(status).json({
    error: {
      message,
      details,
    },
  });
}

export function unwrap(result) {
  if (result.error) {
    throw new Error(result.error.message);
  }
  return result.data;
}
