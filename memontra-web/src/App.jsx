import React from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import LandingPage from './pages/LandingPage';
import Login from './pages/auth/Login';
import Register from './pages/auth/Register';
import { AuthProvider } from './context/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import Booking from './pages/Booking';

import RiwayatBooking from './pages/RiwayatBooking';
import Photobooth from './pages/Photobooth';

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route path="/" element={<LandingPage />} />
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />


          <Route path="/booking" element={
            <ProtectedRoute>
              <Booking />
            </ProtectedRoute>
          } />
          <Route path="/riwayat-booking" element={
            <ProtectedRoute>
              <RiwayatBooking />
            </ProtectedRoute>
          } />
          <Route path="/photobooth" element={<Photobooth />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;