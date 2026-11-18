import React, { useState } from 'react';
import SidebarAdmin from './SidebarAdmin';
import { FaBars } from 'react-icons/fa';
import logo from '../../assets/images/logo-booth-second.png';

const AdminLayout = ({ children }) => {
    const [sidebarOpen, setSidebarOpen] = useState(false);

    return (
        <div className="min-h-screen bg-[#F8FAFC] font-poppins flex flex-col md:flex-row">
            {/* Mobile Top Navbar */}
            <div className="md:hidden bg-white border-b border-gray-100 p-4 flex items-center justify-between sticky top-0 z-30 shadow-xs">
                <button
                    onClick={() => setSidebarOpen(true)}
                    className="p-2 text-dark hover:text-primary rounded-xl hover:bg-gray-50 transition-colors"
                >
                    <FaBars className="text-xl" />
                </button>
                <img src={logo} alt="Logo" className="h-8 w-auto" />
                <div className="w-8" />
            </div>

            {/* Sidebar Kiri */}
            <SidebarAdmin isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />
            
            {/* Konten Kanan */}
            <div className="flex-1 ml-0 md:ml-64 p-4 sm:p-6 md:p-8">
                {children}
            </div>
        </div>
    );
};

export default AdminLayout;
